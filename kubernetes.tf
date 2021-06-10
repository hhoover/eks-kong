provider "aws" {
  region  = var.region
  profile = var.aws_profile
}

data "aws_availability_zones" "available" {}

# reserve Elastic IP to be used in our NAT gateway
resource "aws_eip" "nat_gw_elastic_ip" {
  vpc = true

  tags = merge(
    var.additional_tags,
    {
      Name = "${var.cluster_name}-nat-eip"
    },
  )
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.name_prefix}-vpc"
  cidr = var.vpc_cidr
  azs  = data.aws_availability_zones.available.names

  private_subnets = [
    # this loop will create a one-line list as ["10.0.0.0/20", "10.0.16.0/20", "10.0.32.0/20", ...]
    # with a length depending on how many Zones are available
    for zone_id in data.aws_availability_zones.available.zone_ids :
    cidrsubnet(var.vpc_cidr, var.subnet_prefix_extension, tonumber(substr(zone_id, length(zone_id) - 1, 1)) - 1)
  ]

  public_subnets = [
    # this loop will create a one-line list as ["10.0.128.0/20", "10.0.144.0/20", "10.0.160.0/20", ...]
    # with a length depending on how many Zones are available
    # there is a zone Offset variable, to make sure no collisions are present with private subnet blocks
    for zone_id in data.aws_availability_zones.available.zone_ids :
    cidrsubnet(var.vpc_cidr, var.subnet_prefix_extension, tonumber(substr(zone_id, length(zone_id) - 1, 1)) + var.zone_offset - 1)
  ]

  # enable single NAT Gateway to save some money
  # WARNING: this could create a single point of failure, since we are creating a NAT Gateway in one AZ only
  # feel free to change these options if you need to ensure full Availability without the need of running 'terraform apply'
  # reference: https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/2.44.0#nat-gateway-scenarios
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
  enable_dns_hostnames   = true
  reuse_nat_ips          = true
  external_nat_ip_ids    = [aws_eip.nat_gw_elastic_ip.id]

  # add VPC/Subnet tags required by EKS
  tags = merge(
    var.additional_tags,
    {
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    },
  )
  public_subnet_tags = merge(
    var.additional_tags,
    {
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
      "kubernetes.io/role/elb"                    = "1"
    },
  )
  private_subnet_tags = merge(
    var.additional_tags,
    {
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
      "kubernetes.io/role/internal-elb"           = "1"
    },
  )
}

locals {
  worker_groups_launch_template = [
    {
      override_instance_types = var.asg_instance_types
      asg_desired_capacity    = var.autoscaling_minimum_size_by_az * length(data.aws_availability_zones.available.zone_ids)
      asg_min_size            = var.autoscaling_minimum_size_by_az * length(data.aws_availability_zones.available.zone_ids)
      asg_max_size            = var.autoscaling_maximum_size_by_az * length(data.aws_availability_zones.available.zone_ids)
      kubelet_extra_args      = "--node-labels=node.kubernetes.io/lifecycle=spot" # use Spot EC2 instances to save some money and scale more
      public_ip               = true
    },
  ]
}

module "eks-cluster" {
  source           = "terraform-aws-modules/eks/aws"
  version          = "17.1.0"
  cluster_name     = var.cluster_name
  cluster_version  = "1.20"
  write_kubeconfig = false

  subnets = module.vpc.private_subnets
  vpc_id  = module.vpc.vpc_id

  worker_groups_launch_template = local.worker_groups_launch_template
}

# get EKS cluster info to configure Kubernetes and Helm providers
data "aws_eks_cluster" "cluster" {
  name = module.eks-cluster.cluster_id
}
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks-cluster.cluster_id
}

# get EKS authentication for being able to manage k8s objects from terraform
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# deploy spot termination handler
resource "helm_release" "spot_termination_handler" {
  name       = var.spot_termination_handler_chart_name
  chart      = var.spot_termination_handler_chart_name
  repository = var.spot_termination_handler_chart_repo
  version    = var.spot_termination_handler_chart_version
  namespace  = var.spot_termination_handler_chart_namespace
}

# add spot fleet Autoscaling policy
resource "aws_autoscaling_policy" "eks_autoscaling_policy" {
  count = length(local.worker_groups_launch_template)

  name                   = "${module.eks-cluster.workers_asg_names[count.index]}-autoscaling-policy"
  autoscaling_group_name = module.eks-cluster.workers_asg_names[count.index]
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.autoscaling_average_cpu
  }
}
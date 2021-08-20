# AWS Variables
variable "region" {
  type        = string
  default     = "us-west-2"
  description = "AWS region"
}

variable "aws_profile" {
  type        = string
  default     = "default"
  description = "AWS profile to use from local AWS credentials file"
}

variable "name_prefix" {
  type        = string
  description = "Prefix to be used on each infrastructure object created in AWS."
}

# VPC Variables
variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "Base CIDR block to be used in our VPC."
}

variable "subnet_prefix_extension" {
  type        = number
  default     = 4
  description = "CIDR block bits extension to calculate CIDR blocks of each subnetwork."
}

variable "zone_offset" {
  type        = number
  default     = 8
  description = "CIDR block bits extension offset to calculate Public subnets, avoiding collisions with Private subnets."
}

variable "additional_tags" {
  default     = { "user" : "email@konghq.com" }
  type        = map(string)
  description = "Tags to apply to every resource"
}

# EKS Cluster Variables
variable "cluster_name" {
  default     = "dev"
  description = "Name of the EKS Cluster"
}

variable "asg_instance_types" {
  type        = list(string)
  default     = ["m6i.large", "m6i.xlarge"]
  description = "List of EC2 instance machine types to be used in EKS."
}

variable "autoscaling_minimum_size_by_az" {
  type        = number
  default     = 1
  description = "Minimum number of EC2 instances to autoscale our EKS cluster on each AZ."
}

variable "autoscaling_maximum_size_by_az" {
  type        = number
  default     = 3
  description = "Maximum number of EC2 instances to autoscale our EKS cluster on each AZ."
}

variable "autoscaling_average_cpu" {
  type        = number
  default     = 30
  description = "Average CPU threshold to autoscale EKS EC2 instances."
}

variable "spot_termination_handler_chart_name" {
  type        = string
  default     = "aws-node-termination-handler"
  description = "EKS Spot termination handler Helm chart name."
}

variable "spot_termination_handler_chart_repo" {
  type        = string
  default     = "https://aws.github.io/eks-charts"
  description = "EKS Spot termination handler Helm repository name."
}

variable "spot_termination_handler_chart_version" {
  type        = string
  default     = "0.15.2"
  description = "EKS Spot termination handler Helm chart version."
}

variable "spot_termination_handler_chart_namespace" {
  type        = string
  default     = "kube-system"
  description = "Kubernetes namespace to deploy EKS Spot termination handler Helm chart."
}

# Kong Gateway Variables
variable "dns_base_domain" {
  type        = string
  description = "DNS Zone name to be used for EKS Ingress."
}

variable "kong_gateway_chart_name" {
  type        = string
  default     = "https://github.com/Kong/charts/releases/download/kong-2.3.0/kong-2.3.0.tgz"
  description = "Ingress Gateway Helm chart name."
}

variable "kong_gateway_release_name" {
  type        = string
  default     = "kong"
  description = "Ingress Gateway Helm chart name."
}

variable "kong_superuser_password" {
  type        = string
  description = "Initial SuperAdmin Password for Kong."
}

# Kong Mesh variables
variable "kong_mesh_release_name" {
  type        = string
  default     = "kong-mesh"
  description = "Kong Mesh Helm release name."
}

variable "kong_mesh_chart_name" {
  type        = string
  default     = "kong-mesh"
  description = "Kong Mesh Helm chart name."
}
variable "kong_mesh_chart_repo" {
  type        = string
  default     = "https://kong.github.io/kong-mesh-charts"
  description = "Kong Mesh Helm repository name."
}
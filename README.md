# Kong Mesh / Gateway on EKS

Terraform it up. Creates a VPC, EKS (with spot), and configures an ACM on a load balancer for a domain that should already exist in Route53. This makes use of wildcard dns, so all your Kong services in the gateway should be `something.domain.com`.

Also included: some post-terraform Kube manifests in `./post-manifests` to add observability and mTLS.

## Requirements

Assumes a Kong enterprise `license.json` file in `./gateway` and `./mesh` - you'll need two licenses (one for Gateway and one for Mesh)

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 3.44.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.1.2 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.3.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_eks-cluster"></a> [eks-cluster](#module\_eks-cluster) | terraform-aws-modules/eks/aws | 17.1.0 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_acm_certificate.eks_domain_cert](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate_validation.eks_domain_cert_validation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) | resource |
| [aws_autoscaling_policy.eks_autoscaling_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_policy) | resource |
| [aws_eip.nat_gw_elastic_ip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_route53_record.domain](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.gateway_proxy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [helm_release.kong_gateway](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.kong_mesh](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.spot_termination_handler](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_namespace.kong](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_namespace.kong-mesh-system](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_secret.kong-enterprise-license](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.kong-enterprise-superuser-password](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [kubernetes_secret.kong-mesh-license](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_eks_cluster.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_eks_cluster_auth.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_route53_zone.eks_domain](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [kubernetes_service.kong_gateway](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/service) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_tags"></a> [additional\_tags](#input\_additional\_tags) | Tags to apply to every resource | `map(string)` | <pre>{<br>  "user": "email@konghq.com"<br>}</pre> | no |
| <a name="input_asg_instance_types"></a> [asg\_instance\_types](#input\_asg\_instance\_types) | List of EC2 instance machine types to be used in EKS. | `list(string)` | <pre>[<br>  "t3.small",<br>  "t2.small"<br>]</pre> | no |
| <a name="input_autoscaling_average_cpu"></a> [autoscaling\_average\_cpu](#input\_autoscaling\_average\_cpu) | Average CPU threshold to autoscale EKS EC2 instances. | `number` | `30` | no |
| <a name="input_autoscaling_maximum_size_by_az"></a> [autoscaling\_maximum\_size\_by\_az](#input\_autoscaling\_maximum\_size\_by\_az) | Maximum number of EC2 instances to autoscale our EKS cluster on each AZ. | `number` | `10` | no |
| <a name="input_autoscaling_minimum_size_by_az"></a> [autoscaling\_minimum\_size\_by\_az](#input\_autoscaling\_minimum\_size\_by\_az) | Minimum number of EC2 instances to autoscale our EKS cluster on each AZ. | `number` | `1` | no |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | AWS profile to use from local AWS credentials file | `string` | `"default"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the EKS Cluster | `string` | `"dev"` | no |
| <a name="input_dns_base_domain"></a> [dns\_base\_domain](#input\_dns\_base\_domain) | DNS Zone name to be used for EKS Ingress. | `string` | n/a | yes |
| <a name="input_kong_gateway_chart_name"></a> [kong\_gateway\_chart\_name](#input\_kong\_gateway\_chart\_name) | Ingress Gateway Helm chart name. | `string` | `"https://github.com/Kong/charts/releases/download/kong-2.1.0/kong-2.1.0.tgz"` | no |
| <a name="input_kong_gateway_release_name"></a> [kong\_gateway\_release\_name](#input\_kong\_gateway\_release\_name) | Ingress Gateway Helm chart name. | `string` | `"kong"` | no |
| <a name="input_kong_mesh_chart_name"></a> [kong\_mesh\_chart\_name](#input\_kong\_mesh\_chart\_name) | Kong Mesh Helm chart name. | `string` | `"kong-mesh"` | no |
| <a name="input_kong_mesh_chart_repo"></a> [kong\_mesh\_chart\_repo](#input\_kong\_mesh\_chart\_repo) | Kong Mesh Helm repository name. | `string` | `"https://kong.github.io/kong-mesh-charts"` | no |
| <a name="input_kong_mesh_release_name"></a> [kong\_mesh\_release\_name](#input\_kong\_mesh\_release\_name) | Kong Mesh Helm release name. | `string` | `"kong-mesh"` | no |
| <a name="input_kong_superuser_password"></a> [kong\_superuser\_password](#input\_kong\_superuser\_password) | Initial SuperAdmin Password for Kong. | `string` | n/a | yes |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix to be used on each infrastructure object created in AWS. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | `"us-west-2"` | no |
| <a name="input_spot_termination_handler_chart_name"></a> [spot\_termination\_handler\_chart\_name](#input\_spot\_termination\_handler\_chart\_name) | EKS Spot termination handler Helm chart name. | `string` | `"aws-node-termination-handler"` | no |
| <a name="input_spot_termination_handler_chart_namespace"></a> [spot\_termination\_handler\_chart\_namespace](#input\_spot\_termination\_handler\_chart\_namespace) | Kubernetes namespace to deploy EKS Spot termination handler Helm chart. | `string` | `"kube-system"` | no |
| <a name="input_spot_termination_handler_chart_repo"></a> [spot\_termination\_handler\_chart\_repo](#input\_spot\_termination\_handler\_chart\_repo) | EKS Spot termination handler Helm repository name. | `string` | `"https://aws.github.io/eks-charts"` | no |
| <a name="input_spot_termination_handler_chart_version"></a> [spot\_termination\_handler\_chart\_version](#input\_spot\_termination\_handler\_chart\_version) | EKS Spot termination handler Helm chart version. | `string` | `"0.15.0"` | no |
| <a name="input_subnet_prefix_extension"></a> [subnet\_prefix\_extension](#input\_subnet\_prefix\_extension) | CIDR block bits extension to calculate CIDR blocks of each subnetwork. | `number` | `4` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | Base CIDR block to be used in our VPC. | `string` | `"10.0.0.0/16"` | no |
| <a name="input_zone_offset"></a> [zone\_offset](#input\_zone\_offset) | CIDR block bits extension offset to calculate Public subnets, avoiding collisions with Private subnets. | `number` | `8` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | Endpoint for EKS control plane. |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | EKS cluster ID. |
| <a name="output_cluster_security_group_id"></a> [cluster\_security\_group\_id](#output\_cluster\_security\_group\_id) | Security group ids attached to the cluster control plane. |
| <a name="output_config_map_aws_auth"></a> [config\_map\_aws\_auth](#output\_config\_map\_aws\_auth) | A kubernetes configuration to authenticate to this EKS cluster. |
| <a name="output_kong_domain"></a> [kong\_domain](#output\_kong\_domain) | Access Kong Proxy |
| <a name="output_kubectl_config"></a> [kubectl\_config](#output\_kubectl\_config) | kubectl config as generated by the module. |
| <a name="output_region"></a> [region](#output\_region) | AWS region |

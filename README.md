# Weights & Biases AWS Module

**IMPORTANT:** You are viewing a beta version of the official module to install
Weights & Biases. This new version is incompatible with earlier versions, and it
is not currently meant for production use. Please contact your Customer Success
Manager for details before using.

This is a Terraform module for provisioning a Weights & Biases Cluster on AWS.
Weights & Biases Local is our self-hosted distribution of wandb.ai. It offers
enterprises a private instance of the Weights & Biases application, with no
resource limits and with additional enterprise-grade architectural features like
audit logging and SAML single sign-on.

## About This Module

## Pre-requisites

This module is intended to run in an AWS account with minimal preparation,
however it does have the following pre-requisites:

### Terrafom version >= 1.9

### Credentials / Permissions

#### AWS Services Used

- AWS Identity & Access Management (IAM)
- AWS Key Management System (KMS)
- Amazon Aurora MySQL (RDS)
- Amazon VPC
- Amazon S3
- Amazon Route53
- Amazon Certificate Manager (ACM)
- Amazon Elastic Loadbalancing (ALB)
- Amazon Secrets Manager

### Public Hosted Zone

If you are managing DNS via AWS Route53 the hosted zone entry is created
automatically as part of your domain management.

If you're managing DNS outside of Route53, you will need to:

1. Create a Route53 zone name `{subdomain}.{domain}` (e.g `test.wandb.ai`)
2. Create a NS record in your parent system and point it to the newly created
   Route53
3. Enable the `external_dns` option in this module

You can learn more about [creating a hosted zone for a
subdomain](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-routing-traffic-for-subdomains.html),
which you will need to do for the subdomain you are planning to use for your
Weights & Biases installation. To create this hosted zone with Terraform, use
[the `aws_route53_zone`
resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone).

### ACM Certificate

While this is not required, it is recommend to already have an existing ACM
certification. Certificate validation can take up two hours, causing timeouts
during module apply if the cert is generated as one of the resources contained
in the module.

## How to Use This Module

- Ensure account meets module pre-requisites from above.
- Please note that while some resources are individually and uniquely tagged,
  all common tags are expected to be configured within the AWS provider as shown
  in the example code snippet below.

- Create a Terraform configuration that pulls in this module and specifies
  values of the required variables:

```hcl
provider "aws" {
  region = "<your AWS region>"
  default_tags {
    tags = var.common_tags
  }
}

module "wandb" {
  source    = "<filepath to cloned module directory>"
  namespace = "<prefix for naming AWS resources>"
}
```

- Run `terraform init` and `terraform apply`

## Cluster Sizing

By default, the type of kubernetes instances, number of instances, redis cluster size, and database instance sizes are
standardized via configurations in [./deployment-size.tf](deployment-size.tf), and is configured via the `size` input
variable.

Available sizes are, `small`, `medium`, `large`, `xlarge`, and `xxlarge`.  Default is `small`.

All the values set via `deployment-size.tf` can be overridden by setting the appropriate input variables.

- `kubernetes_instance_types` - The instance type for the EKS nodes
- `kubernetes_min_nodes_per_az` - The minimum number of nodes in each AZ for the EKS cluster
- `kubernetes_max_nodes_per_az` - The maximum number of nodes in each AZ for the EKS cluster
- `elasticache_node_type` - The instance type for the redis cluster
- `database_instance_class` - The instance type for the database

## Examples

We have included documentation and reference examples for additional common
installation scenarios for Weights & Biases, as well as examples for supporting
resources that lack official modules.

- [Private Access Only](https://github.com/wandb/terraform-aws-wandb/tree/main/examples/private-access-only)
- [Private Existing Network](https://github.com/wandb/terraform-aws-wandb/tree/main/examples/private-existing-network)
- [Public External DNS](https://github.com/wandb/terraform-aws-wandb/tree/main/examples/public-dns-external)
- [Public Route 53 DNS](https://github.com/wandb/terraform-aws-wandb/tree/main/examples/public-dns-with-route53)

### A note on updating EKS cluster version

Users can update the EKS cluster version to the latest version offered by AWS. This can be done using the environment variable `eks_cluster_version`. Note that, cluster and nodegroup version updates can only be done in increments of one version at a time. For example, if your current cluster version is `1.21` and the latest version available is `1.25` - you'd need to:

1. update the cluster version in the app_eks module from `1.21` to `1.22`
2. run `terraform apply`
3. update the cluster version to `1.23`
4. run `terraform apply`
5. update the cluster version to `1.24`
   ...and so on and so forth.

Upgrades must be executed in step-wise fashion from one version to the next. You cannot skip versions when upgrading EKS.

<!-- BEGIN_TF_DOCS -->

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.23 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.67.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_acm"></a> [acm](#module\_acm) | terraform-aws-modules/acm/aws | ~> 3.0 |
| <a name="module_app_eks"></a> [app\_eks](#module\_app\_eks) | ./modules/app_eks | n/a |
| <a name="module_app_lb"></a> [app\_lb](#module\_app\_lb) | ./modules/app_lb | n/a |
| <a name="module_database"></a> [database](#module\_database) | ./modules/database | n/a |
| <a name="module_file_storage"></a> [file\_storage](#module\_file\_storage) | ./modules/file_storage | n/a |
| <a name="module_iam_role"></a> [iam\_role](#module\_iam\_role) | ./modules/iam_role | n/a |
| <a name="module_kms"></a> [kms](#module\_kms) | ./modules/kms | n/a |
| <a name="module_networking"></a> [networking](#module\_networking) | ./modules/networking | n/a |
| <a name="module_private_link"></a> [private\_link](#module\_private\_link) | ./modules/private_link | n/a |
| <a name="module_redis"></a> [redis](#module\_redis) | ./modules/redis | n/a |
| <a name="module_s3_endpoint"></a> [s3\_endpoint](#module\_s3\_endpoint) | ./modules/endpoint | n/a |
| <a name="module_wandb"></a> [wandb](#module\_wandb) | wandb/wandb/helm | 1.2.0 |

## Resources

| Name | Type |
|------|------|
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_s3_bucket.file_storage](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_bucket) | data source |
| [aws_sqs_queue.file_storage](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/sqs_queue) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acm_certificate_arn"></a> [acm\_certificate\_arn](#input\_acm\_certificate\_arn) | The ARN of an existing ACM certificate. | `string` | `null` | no |
| <a name="input_allowed_inbound_cidr"></a> [allowed\_inbound\_cidr](#input\_allowed\_inbound\_cidr) | CIDRs allowed to access wandb-server. | `list(string)` | n/a | yes |
| <a name="input_allowed_inbound_ipv6_cidr"></a> [allowed\_inbound\_ipv6\_cidr](#input\_allowed\_inbound\_ipv6\_cidr) | CIDRs allowed to access wandb-server. | `list(string)` | n/a | yes |
| <a name="input_allowed_private_endpoint_cidr"></a> [allowed\_private\_endpoint\_cidr](#input\_allowed\_private\_endpoint\_cidr) | Private CIDRs allowed to access wandb-server. | `list(string)` | `[]` | no |
| <a name="input_app_wandb_env"></a> [app\_wandb\_env](#input\_app\_wandb\_env) | Extra environment variables for W&B | `map(string)` | `{}` | no |
| <a name="input_aws_loadbalancer_controller_tags"></a> [aws\_loadbalancer\_controller\_tags](#input\_aws\_loadbalancer\_controller\_tags) | (Optional) A map of AWS tags to apply to all resources managed by the load balancer controller | `map(string)` | `{}` | no |
| <a name="input_bucket_kms_key_arn"></a> [bucket\_kms\_key\_arn](#input\_bucket\_kms\_key\_arn) | n/a | `string` | `""` | no |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | n/a | `string` | `""` | no |
| <a name="input_bucket_path"></a> [bucket\_path](#input\_bucket\_path) | path of where to store data for the instance-level bucket | `string` | `""` | no |
| <a name="input_clickhouse_endpoint_service_id"></a> [clickhouse\_endpoint\_service\_id](#input\_clickhouse\_endpoint\_service\_id) | The service ID of the VPC endpoint service for Clickhouse | `string` | `""` | no |
| <a name="input_controller_image_tag"></a> [controller\_image\_tag](#input\_controller\_image\_tag) | Tag of the controller image to deploy | `string` | `"1.14.0"` | no |
| <a name="input_create_bucket"></a> [create\_bucket](#input\_create\_bucket) | ######################################### External Bucket                        # ######################################### Most users will not need these settings. They are ment for users who want a bucket and sqs that are in a different account. | `bool` | `true` | no |
| <a name="input_create_elasticache"></a> [create\_elasticache](#input\_create\_elasticache) | Boolean indicating whether to provision an elasticache instance (true) or not (false). | `bool` | `true` | no |
| <a name="input_create_vpc"></a> [create\_vpc](#input\_create\_vpc) | Boolean indicating whether to deploy a VPC (true) or not (false). | `bool` | `true` | no |
| <a name="input_custom_domain_filter"></a> [custom\_domain\_filter](#input\_custom\_domain\_filter) | A custom domain filter to be used by external-dns instead of the default FQDN. If not set, the local FQDN is used. | `string` | `null` | no |
| <a name="input_database_binlog_format"></a> [database\_binlog\_format](#input\_database\_binlog\_format) | Specifies the binlog\_format value to set for the database | `string` | `"ROW"` | no |
| <a name="input_database_engine_version"></a> [database\_engine\_version](#input\_database\_engine\_version) | Version for MySQL Aurora | `string` | `"8.0.mysql_aurora.3.07.1"` | no |
| <a name="input_database_innodb_lru_scan_depth"></a> [database\_innodb\_lru\_scan\_depth](#input\_database\_innodb\_lru\_scan\_depth) | Specifies the innodb\_lru\_scan\_depth value to set for the database | `number` | `128` | no |
| <a name="input_database_instance_class"></a> [database\_instance\_class](#input\_database\_instance\_class) | Instance type to use by database master instance. | `string` | `"db.r5.large"` | no |
| <a name="input_database_kms_key_arn"></a> [database\_kms\_key\_arn](#input\_database\_kms\_key\_arn) | n/a | `string` | `""` | no |
| <a name="input_database_master_username"></a> [database\_master\_username](#input\_database\_master\_username) | Specifies the master\_username value to set for the database | `string` | `"wandb"` | no |
| <a name="input_database_name"></a> [database\_name](#input\_database\_name) | Specifies the name of the database | `string` | `"wandb_local"` | no |
| <a name="input_database_performance_insights_kms_key_arn"></a> [database\_performance\_insights\_kms\_key\_arn](#input\_database\_performance\_insights\_kms\_key\_arn) | Specifies an existing KMS key ARN to encrypt the performance insights data if performance\_insights\_enabled is was enabled out of band | `string` | `""` | no |
| <a name="input_database_snapshot_identifier"></a> [database\_snapshot\_identifier](#input\_database\_snapshot\_identifier) | Specifies whether or not to create this cluster from a snapshot. You can use either the name or ARN when specifying a DB cluster snapshot, or the ARN when specifying a DB snapshot | `string` | `null` | no |
| <a name="input_database_sort_buffer_size"></a> [database\_sort\_buffer\_size](#input\_database\_sort\_buffer\_size) | Specifies the sort\_buffer\_size value to set for the database | `number` | `67108864` | no |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | If the instance should have deletion protection enabled. The database / S3 can't be deleted when this value is set to `true`. | `bool` | `true` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain for accessing the Weights & Biases UI. | `string` | n/a | yes |
| <a name="input_eks_cluster_version"></a> [eks\_cluster\_version](#input\_eks\_cluster\_version) | EKS cluster kubernetes version | `string` | n/a | yes |
| <a name="input_eks_policy_arns"></a> [eks\_policy\_arns](#input\_eks\_policy\_arns) | Additional IAM policy to apply to the EKS cluster | `list(string)` | `[]` | no |
| <a name="input_elasticache_node_type"></a> [elasticache\_node\_type](#input\_elasticache\_node\_type) | The type of the redis cache node to deploy | `string` | `"cache.t2.medium"` | no |
| <a name="input_enable_clickhouse"></a> [enable\_clickhouse](#input\_enable\_clickhouse) | Provision clickhouse resources | `bool` | `false` | no |
| <a name="input_enable_yace"></a> [enable\_yace](#input\_enable\_yace) | deploy yet another cloudwatch exporter to fetch aws resources metrics | `bool` | `true` | no |
| <a name="input_external_dns"></a> [external\_dns](#input\_external\_dns) | Using external DNS. A `subdomain` must also be specified if this value is true. | `bool` | `false` | no |
| <a name="input_extra_fqdn"></a> [extra\_fqdn](#input\_extra\_fqdn) | Additional fqdn's must be in the same hosted zone as `domain_name`. | `list(string)` | `[]` | no |
| <a name="input_kms_clickhouse_key_alias"></a> [kms\_clickhouse\_key\_alias](#input\_kms\_clickhouse\_key\_alias) | KMS key alias for AWS KMS Customer managed key used by Clickhouse CMEK. | `string` | `null` | no |
| <a name="input_kms_clickhouse_key_policy"></a> [kms\_clickhouse\_key\_policy](#input\_kms\_clickhouse\_key\_policy) | The policy that will define the permissions for the clickhouse kms key. | `string` | `""` | no |
| <a name="input_kms_key_alias"></a> [kms\_key\_alias](#input\_kms\_key\_alias) | KMS key alias for AWS KMS Customer managed key. | `string` | `null` | no |
| <a name="input_kms_key_deletion_window"></a> [kms\_key\_deletion\_window](#input\_kms\_key\_deletion\_window) | Duration in days to destroy the key after it is deleted. Must be between 7 and 30 days. | `number` | `7` | no |
| <a name="input_kms_key_policy"></a> [kms\_key\_policy](#input\_kms\_key\_policy) | The policy that will define the permissions for the kms key. | `string` | `""` | no |
| <a name="input_kms_key_policy_administrator_arn"></a> [kms\_key\_policy\_administrator\_arn](#input\_kms\_key\_policy\_administrator\_arn) | The principal that will be allowed to manage the kms key. | `string` | `""` | no |
| <a name="input_kubernetes_alb_internet_facing"></a> [kubernetes\_alb\_internet\_facing](#input\_kubernetes\_alb\_internet\_facing) | Indicates whether or not the ALB controlled by the Amazon ALB ingress controller is internet-facing or internal. | `bool` | `true` | no |
| <a name="input_kubernetes_alb_subnets"></a> [kubernetes\_alb\_subnets](#input\_kubernetes\_alb\_subnets) | List of subnet ID's the ALB will use for ingress traffic. | `list(string)` | `[]` | no |
| <a name="input_kubernetes_instance_types"></a> [kubernetes\_instance\_types](#input\_kubernetes\_instance\_types) | EC2 Instance type for primary node group. | `list(string)` | <pre>[<br>  "m5.large"<br>]</pre> | no |
| <a name="input_kubernetes_map_accounts"></a> [kubernetes\_map\_accounts](#input\_kubernetes\_map\_accounts) | Additional AWS account numbers to add to the aws-auth configmap. | `list(string)` | `[]` | no |
| <a name="input_kubernetes_map_roles"></a> [kubernetes\_map\_roles](#input\_kubernetes\_map\_roles) | Additional IAM roles to add to the aws-auth configmap. | <pre>list(object({<br>    rolearn  = string<br>    username = string<br>    groups   = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_kubernetes_map_users"></a> [kubernetes\_map\_users](#input\_kubernetes\_map\_users) | Additional IAM users to add to the aws-auth configmap. | <pre>list(object({<br>    userarn  = string<br>    username = string<br>    groups   = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_kubernetes_node_count"></a> [kubernetes\_node\_count](#input\_kubernetes\_node\_count) | Number of nodes | `number` | `2` | no |
| <a name="input_kubernetes_public_access"></a> [kubernetes\_public\_access](#input\_kubernetes\_public\_access) | Indicates whether or not the Amazon EKS public API server endpoint is enabled. | `bool` | `false` | no |
| <a name="input_kubernetes_public_access_cidrs"></a> [kubernetes\_public\_access\_cidrs](#input\_kubernetes\_public\_access\_cidrs) | List of CIDR blocks which can access the Amazon EKS public API server endpoint. | `list(string)` | `[]` | no |
| <a name="input_license"></a> [license](#input\_license) | Weights & Biases license key. | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | String used for prefix resources. | `string` | n/a | yes |
| <a name="input_network_cidr"></a> [network\_cidr](#input\_network\_cidr) | CIDR block for VPC. | `string` | `"10.10.0.0/16"` | no |
| <a name="input_network_database_subnet_cidrs"></a> [network\_database\_subnet\_cidrs](#input\_network\_database\_subnet\_cidrs) | List of private subnet CIDR ranges to create in VPC. | `list(string)` | <pre>[<br>  "10.10.20.0/24",<br>  "10.10.21.0/24"<br>]</pre> | no |
| <a name="input_network_database_subnets"></a> [network\_database\_subnets](#input\_network\_database\_subnets) | A list of the identities of the database subnetworks in which resources will be deployed. | `list(string)` | `[]` | no |
| <a name="input_network_elasticache_subnet_cidrs"></a> [network\_elasticache\_subnet\_cidrs](#input\_network\_elasticache\_subnet\_cidrs) | List of private subnet CIDR ranges to create in VPC. | `list(string)` | <pre>[<br>  "10.10.30.0/24",<br>  "10.10.31.0/24"<br>]</pre> | no |
| <a name="input_network_elasticache_subnets"></a> [network\_elasticache\_subnets](#input\_network\_elasticache\_subnets) | A list of the identities of the subnetworks in which elasticache resources will be deployed. | `list(string)` | `[]` | no |
| <a name="input_network_id"></a> [network\_id](#input\_network\_id) | The identity of the VPC in which resources will be deployed. | `string` | `""` | no |
| <a name="input_network_private_subnet_cidrs"></a> [network\_private\_subnet\_cidrs](#input\_network\_private\_subnet\_cidrs) | List of private subnet CIDR ranges to create in VPC. | `list(string)` | <pre>[<br>  "10.10.10.0/24",<br>  "10.10.11.0/24"<br>]</pre> | no |
| <a name="input_network_private_subnets"></a> [network\_private\_subnets](#input\_network\_private\_subnets) | A list of the identities of the private subnetworks in which resources will be deployed. | `list(string)` | `[]` | no |
| <a name="input_network_public_subnet_cidrs"></a> [network\_public\_subnet\_cidrs](#input\_network\_public\_subnet\_cidrs) | List of private subnet CIDR ranges to create in VPC. | `list(string)` | <pre>[<br>  "10.10.0.0/24",<br>  "10.10.1.0/24"<br>]</pre> | no |
| <a name="input_network_public_subnets"></a> [network\_public\_subnets](#input\_network\_public\_subnets) | A list of the identities of the public subnetworks in which resources will be deployed. | `list(string)` | `[]` | no |
| <a name="input_operator_chart_version"></a> [operator\_chart\_version](#input\_operator\_chart\_version) | Version of the operator chart to deploy | `string` | `"1.3.4"` | no |
| <a name="input_other_wandb_env"></a> [other\_wandb\_env](#input\_other\_wandb\_env) | Extra environment variables for W&B | `map(any)` | `{}` | no |
| <a name="input_parquet_wandb_env"></a> [parquet\_wandb\_env](#input\_parquet\_wandb\_env) | Extra environment variables for W&B | `map(string)` | `{}` | no |
| <a name="input_private_link_allowed_account_ids"></a> [private\_link\_allowed\_account\_ids](#input\_private\_link\_allowed\_account\_ids) | List of AWS account IDs allowed to access the VPC Endpoint Service | `list(string)` | `[]` | no |
| <a name="input_private_only_traffic"></a> [private\_only\_traffic](#input\_private\_only\_traffic) | Enable private only traffic from customer private network | `bool` | `false` | no |
| <a name="input_public_access"></a> [public\_access](#input\_public\_access) | Is this instance accessable a public domain. | `bool` | `false` | no |
| <a name="input_size"></a> [size](#input\_size) | Deployment size | `string` | `null` | no |
| <a name="input_ssl_policy"></a> [ssl\_policy](#input\_ssl\_policy) | SSL policy to use on ALB listener | `string` | `"ELBSecurityPolicy-FS-1-2-Res-2020-10"` | no |
| <a name="input_subdomain"></a> [subdomain](#input\_subdomain) | Subdomain for accessing the Weights & Biases UI. Default creates record at Route53 Route. | `string` | `null` | no |
| <a name="input_system_reserved_cpu_millicores"></a> [system\_reserved\_cpu\_millicores](#input\_system\_reserved\_cpu\_millicores) | (Optional) The amount of 'system-reserved' CPU millicores to pass to the kubelet. For example: 100.  A value of -1 disables the flag. | `number` | `70` | no |
| <a name="input_system_reserved_ephemeral_megabytes"></a> [system\_reserved\_ephemeral\_megabytes](#input\_system\_reserved\_ephemeral\_megabytes) | (Optional) The amount of 'system-reserved' ephemeral storage in megabytes to pass to the kubelet. For example: 1000.  A value of -1 disables the flag. | `number` | `750` | no |
| <a name="input_system_reserved_memory_megabytes"></a> [system\_reserved\_memory\_megabytes](#input\_system\_reserved\_memory\_megabytes) | (Optional) The amount of 'system-reserved' memory in megabytes to pass to the kubelet. For example: 100.  A value of -1 disables the flag. | `number` | `100` | no |
| <a name="input_system_reserved_pid"></a> [system\_reserved\_pid](#input\_system\_reserved\_pid) | (Optional) The amount of 'system-reserved' process ids [pid] to pass to the kubelet. For example: 1000.  A value of -1 disables the flag. | `number` | `500` | no |
| <a name="input_use_internal_queue"></a> [use\_internal\_queue](#input\_use\_internal\_queue) | n/a | `bool` | `false` | no |
| <a name="input_weave_wandb_env"></a> [weave\_wandb\_env](#input\_weave\_wandb\_env) | Extra environment variables for W&B | `map(string)` | `{}` | no |
| <a name="input_yace_sa_name"></a> [yace\_sa\_name](#input\_yace\_sa\_name) | n/a | `string` | `"wandb-yace"` | no |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | Domain for creating the Weights & Biases subdomain on. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | n/a |
| <a name="output_bucket_path"></a> [bucket\_path](#output\_bucket\_path) | n/a |
| <a name="output_bucket_queue_name"></a> [bucket\_queue\_name](#output\_bucket\_queue\_name) | n/a |
| <a name="output_bucket_region"></a> [bucket\_region](#output\_bucket\_region) | n/a |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | n/a |
| <a name="output_cluster_node_role"></a> [cluster\_node\_role](#output\_cluster\_node\_role) | n/a |
| <a name="output_database_connection_string"></a> [database\_connection\_string](#output\_database\_connection\_string) | n/a |
| <a name="output_database_instance_type"></a> [database\_instance\_type](#output\_database\_instance\_type) | n/a |
| <a name="output_database_password"></a> [database\_password](#output\_database\_password) | n/a |
| <a name="output_database_username"></a> [database\_username](#output\_database\_username) | n/a |
| <a name="output_eks_node_count"></a> [eks\_node\_count](#output\_eks\_node\_count) | n/a |
| <a name="output_eks_node_instance_type"></a> [eks\_node\_instance\_type](#output\_eks\_node\_instance\_type) | n/a |
| <a name="output_elasticache_connection_string"></a> [elasticache\_connection\_string](#output\_elasticache\_connection\_string) | n/a |
| <a name="output_kms_clickhouse_key_arn"></a> [kms\_clickhouse\_key\_arn](#output\_kms\_clickhouse\_key\_arn) | The Amazon Resource Name of the KMS key used to encrypt Weave data at rest in Clickhouse. |
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | The Amazon Resource Name of the KMS key used to encrypt data at rest. |
| <a name="output_network_id"></a> [network\_id](#output\_network\_id) | The identity of the VPC in which resources are deployed. |
| <a name="output_network_private_subnets"></a> [network\_private\_subnets](#output\_network\_private\_subnets) | The identities of the private subnetworks deployed within the VPC. |
| <a name="output_network_public_subnets"></a> [network\_public\_subnets](#output\_network\_public\_subnets) | The identities of the public subnetworks deployed within the VPC. |
| <a name="output_redis_instance_type"></a> [redis\_instance\_type](#output\_redis\_instance\_type) | n/a |
| <a name="output_standardized_size"></a> [standardized\_size](#output\_standardized\_size) | n/a |
| <a name="output_url"></a> [url](#output\_url) | The URL to the W&B application |

<!-- END_TF_DOCS -->

## Migrations

### Upgrading to Operator

See our upgrade guide [here](./docs/operator-migration/readme.md)

### Upgrading from 4.x -> 5.x

5.0.0 introduced autoscaling to the EKS cluster and made the `size` variable the preferred way to set the cluster size.
Previously, unless the `size` variable was set explicitly, there were default values for the following variables:
- `kubernetes_instance_types`
- `kubernetes_node_count`
- `elasticache_node_type`
- `database_instance_class`

The `size` variable is now defaulted to `small`, and the following values to can be used to partially override the values
set by the `size` variable:
- `kubernetes_instance_types`
- `kubernetes_min_nodes_per_az`
- `kubernetes_max_nodes_per_az`
- `elasticache_node_type`
- `database_instance_class`

For more information on the available sizes, see the [Cluster Sizing](#cluster-sizing) section.

If having the cluster scale nodes in and out is not desired, the `kubernetes_min_nodes_per_az` and 
`kubernetes_max_nodes_per_az` can be set to the same value to prevent the cluster from scaling.

This upgrade is also intended to be used when upgrading eks to 1.29.

We have upgraded the following dependencies and Kubernetes addons:

- MySQL Aurora (8.0.mysql_aurora.3.07.1)
- redis (7.1)
- external-dns helm chart (v1.15.0)
- aws-efs-csi-driver (v2.0.7-eksbuild.1)
- aws-ebs-csi-driver (v1.35.0-eksbuild.1)
- coredns (v1.11.3-eksbuild.1)
- kube-proxy (v1.29.7-eksbuild.9)
- vpc-cni (v1.18.3-eksbuild.3)

> :warning: Please remove the `enable_dummy_dns` and `enable_operator_alb` variables
> as they are no longer valid flags. They were provided to support older versions of
> the module that relied on an alb not created by the ingress controller.

### Upgrading from 3.x -> 4.x

- If egress access for retrieving the wandb/controller image is not available, Terraform apply may experience failures.
- It's necessary to supply a license variable within the module, as shown:

```hcl
module "wandb" {
  version = "4.x"

  # ...
  license = "<your license key>"
  # ...
}
```

### Alow customer specific customer-managed keys for S3 and RDS

- we can provide external kms key to encrypt database, redis and S3 buckets.
- To provide kms keys we need to provide kms arn values in

```
database_kms_key_arn
bucket_kms_key_arn
```

### In order to allow cross account KMS keys. we need to allow kms keys to be accessed by WandB account.

This can be donw by adding the following policy document.

```
{
      "Sid": "Allow use of the key",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::<Account_id>:root"
        ]
      },
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey",
        "kms:CreateGrant"
      ],
      "Resource": "*"
    }
```

### 6.x -> 7.x

`v7` changes how the module references storage from using terraform's `count` to always creating a "defaultBucket" which can be overidden latter or but providing some initial bucket.

We are considering this a major change because of the terraform `moved` block which migrates the resource. After moving to a `v7` applying an earlier version of the module may result in terraform deleting your bucket.

removed the `create_bucket` var due to the above.
### Upgrading from 2.x -> 3.x

- No changes required by you

### Upgrading from 1.x -> 2.x

- ~>4.0 version required for AWS Provider

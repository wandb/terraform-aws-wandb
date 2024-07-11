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

### Terrafom version >= 1.5

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

| Name                                                                        | Version |
| --------------------------------------------------------------------------- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform)    | ~> 1.0  |
| <a name="requirement_aws"></a> [aws](#requirement_aws)                      | ~> 4.0  |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement_kubernetes) | ~> 2.23 |

## Providers

| Name                                             | Version |
| ------------------------------------------------ | ------- |
| <a name="provider_aws"></a> [aws](#provider_aws) | ~> 4.0  |

## Modules

| Name                                                                    | Source                        | Version |
| ----------------------------------------------------------------------- | ----------------------------- | ------- |
| <a name="module_acm"></a> [acm](#module_acm)                            | terraform-aws-modules/acm/aws | ~> 3.0  |
| <a name="module_app_eks"></a> [app_eks](#module_app_eks)                | ./modules/app_eks             | n/a     |
| <a name="module_app_lb"></a> [app_lb](#module_app_lb)                   | ./modules/app_lb              | n/a     |
| <a name="module_database"></a> [database](#module_database)             | ./modules/database            | n/a     |
| <a name="module_file_storage"></a> [file_storage](#module_file_storage) | ./modules/file_storage        | n/a     |
| <a name="module_iam_role"></a> [iam_role](#module_iam_role)             | ./modules/iam_role            | n/a     |
| <a name="module_kms"></a> [kms](#module_kms)                            | ./modules/kms                 | n/a     |
| <a name="module_networking"></a> [networking](#module_networking)       | ./modules/networking          | n/a     |
| <a name="module_private_link"></a> [private_link](#module_private_link) | ./modules/private_link        | n/a     |
| <a name="module_redis"></a> [redis](#module_redis)                      | ./modules/redis               | n/a     |
| <a name="module_s3_endpoint"></a> [s3_endpoint](#module_s3_endpoint)    | ./modules/endpoint            | n/a     |
| <a name="module_wandb"></a> [wandb](#module_wandb)                      | wandb/wandb/helm              | 1.2.0   |

## Resources

| Name                                                                                                                   | Type        |
| ---------------------------------------------------------------------------------------------------------------------- | ----------- |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region)            | data source |
| [aws_s3_bucket.file_storage](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_bucket) | data source |
| [aws_sqs_queue.file_storage](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/sqs_queue) | data source |

## Inputs

| Name                                                                                                                                                         | Description                                                                                                                                                                                                                       | Type                                                                                                  | Default                                                    | Required |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- | ---------------------------------------------------------- | :------: |
| <a name="input_acm_certificate_arn"></a> [acm_certificate_arn](#input_acm_certificate_arn)                                                                   | The ARN of an existing ACM certificate.                                                                                                                                                                                           | `string`                                                                                              | `null`                                                     |    no    |
| <a name="input_allowed_inbound_cidr"></a> [allowed_inbound_cidr](#input_allowed_inbound_cidr)                                                                | CIDRs allowed to access wandb-server.                                                                                                                                                                                             | `list(string)`                                                                                        | n/a                                                        |   yes    |
| <a name="input_allowed_inbound_ipv6_cidr"></a> [allowed_inbound_ipv6_cidr](#input_allowed_inbound_ipv6_cidr)                                                 | CIDRs allowed to access wandb-server.                                                                                                                                                                                             | `list(string)`                                                                                        | n/a                                                        |   yes    |
| <a name="input_allowed_private_endpoint_cidr"></a> [allowed_private_endpoint_cidr](#input_allowed_private_endpoint_cidr)                                     | Private CIDRs allowed to access wandb-server.                                                                                                                                                                                     | `list(string)`                                                                                        | `[]`                                                       |    no    |
| <a name="input_app_wandb_env"></a> [app_wandb_env](#input_app_wandb_env)                                                                                     | Extra environment variables for W&B                                                                                                                                                                                               | `map(string)`                                                                                         | `{}`                                                       |    no    |
| <a name="input_aws_loadbalancer_controller_tags"></a> [aws_loadbalancer_controller_tags](#input_aws_loadbalancer_controller_tags)                            | (Optional) A map of AWS tags to apply to all resources managed by the load balancer controller                                                                                                                                    | `map(string)`                                                                                         | `{}`                                                       |    no    |
| <a name="input_bucket_kms_key_arn"></a> [bucket_kms_key_arn](#input_bucket_kms_key_arn)                                                                      | n/a                                                                                                                                                                                                                               | `string`                                                                                              | `""`                                                       |    no    |
| <a name="input_bucket_name"></a> [bucket_name](#input_bucket_name)                                                                                           | n/a                                                                                                                                                                                                                               | `string`                                                                                              | `""`                                                       |    no    |
| <a name="input_create_bucket"></a> [create_bucket](#input_create_bucket)                                                                                     | ######################################### External Bucket # ######################################### Most users will not need these settings. They are ment for users who want a bucket and sqs that are in a different account. | `bool`                                                                                                | `true`                                                     |    no    |
| <a name="input_create_elasticache"></a> [create_elasticache](#input_create_elasticache)                                                                      | Boolean indicating whether to provision an elasticache instance (true) or not (false).                                                                                                                                            | `bool`                                                                                                | `true`                                                     |    no    |
| <a name="input_create_vpc"></a> [create_vpc](#input_create_vpc)                                                                                              | Boolean indicating whether to deploy a VPC (true) or not (false).                                                                                                                                                                 | `bool`                                                                                                | `true`                                                     |    no    |
| <a name="input_custom_domain_filter"></a> [custom_domain_filter](#input_custom_domain_filter)                                                                | A custom domain filter to be used by external-dns instead of the default FQDN. If not set, the local FQDN is used.                                                                                                                | `string`                                                                                              | `null`                                                     |    no    |
| <a name="input_database_binlog_format"></a> [database_binlog_format](#input_database_binlog_format)                                                          | Specifies the binlog_format value to set for the database                                                                                                                                                                         | `string`                                                                                              | `"ROW"`                                                    |    no    |
| <a name="input_database_engine_version"></a> [database_engine_version](#input_database_engine_version)                                                       | Version for MySQL Auora                                                                                                                                                                                                           | `string`                                                                                              | `"8.0.mysql_aurora.3.05.2"`                                |    no    |
| <a name="input_database_innodb_lru_scan_depth"></a> [database_innodb_lru_scan_depth](#input_database_innodb_lru_scan_depth)                                  | Specifies the innodb_lru_scan_depth value to set for the database                                                                                                                                                                 | `number`                                                                                              | `128`                                                      |    no    |
| <a name="input_database_instance_class"></a> [database_instance_class](#input_database_instance_class)                                                       | Instance type to use by database master instance.                                                                                                                                                                                 | `string`                                                                                              | `"db.r5.large"`                                            |    no    |
| <a name="input_database_kms_key_arn"></a> [database_kms_key_arn](#input_database_kms_key_arn)                                                                | n/a                                                                                                                                                                                                                               | `string`                                                                                              | `""`                                                       |    no    |
| <a name="input_database_master_username"></a> [database_master_username](#input_database_master_username)                                                    | Specifies the master_username value to set for the database                                                                                                                                                                       | `string`                                                                                              | `"wandb"`                                                  |    no    |
| <a name="input_database_name"></a> [database_name](#input_database_name)                                                                                     | Specifies the name of the database                                                                                                                                                                                                | `string`                                                                                              | `"wandb_local"`                                            |    no    |
| <a name="input_database_performance_insights_kms_key_arn"></a> [database_performance_insights_kms_key_arn](#input_database_performance_insights_kms_key_arn) | Specifies an existing KMS key ARN to encrypt the performance insights data if performance_insights_enabled is was enabled out of band                                                                                             | `string`                                                                                              | `""`                                                       |    no    |
| <a name="input_database_snapshot_identifier"></a> [database_snapshot_identifier](#input_database_snapshot_identifier)                                        | Specifies whether or not to create this cluster from a snapshot. You can use either the name or ARN when specifying a DB cluster snapshot, or the ARN when specifying a DB snapshot                                               | `string`                                                                                              | `null`                                                     |    no    |
| <a name="input_database_sort_buffer_size"></a> [database_sort_buffer_size](#input_database_sort_buffer_size)                                                 | Specifies the sort_buffer_size value to set for the database                                                                                                                                                                      | `number`                                                                                              | `67108864`                                                 |    no    |
| <a name="input_deletion_protection"></a> [deletion_protection](#input_deletion_protection)                                                                   | If the instance should have deletion protection enabled. The database / S3 can't be deleted when this value is set to `true`.                                                                                                     | `bool`                                                                                                | `true`                                                     |    no    |
| <a name="input_domain_name"></a> [domain_name](#input_domain_name)                                                                                           | Domain for accessing the Weights & Biases UI.                                                                                                                                                                                     | `string`                                                                                              | n/a                                                        |   yes    |
| <a name="input_eks_cluster_version"></a> [eks_cluster_version](#input_eks_cluster_version)                                                                   | EKS cluster kubernetes version                                                                                                                                                                                                    | `string`                                                                                              | n/a                                                        |   yes    |
| <a name="input_eks_policy_arns"></a> [eks_policy_arns](#input_eks_policy_arns)                                                                               | Additional IAM policy to apply to the EKS cluster                                                                                                                                                                                 | `list(string)`                                                                                        | `[]`                                                       |    no    |
| <a name="input_elasticache_node_type"></a> [elasticache_node_type](#input_elasticache_node_type)                                                             | The type of the redis cache node to deploy                                                                                                                                                                                        | `string`                                                                                              | `"cache.t2.medium"`                                        |    no    |
| <a name="input_enable_dummy_dns"></a> [enable_dummy_dns](#input_enable_dummy_dns)                                                                            | Boolean indicating whether or not to enable dummy DNS for the old alb                                                                                                                                                             | `bool`                                                                                                | `false`                                                    |    no    |
| <a name="input_enable_operator_alb"></a> [enable_operator_alb](#input_enable_operator_alb)                                                                   | Boolean indicating whether to use operatore ALB (true) or not (false).                                                                                                                                                            | `bool`                                                                                                | `false`                                                    |    no    |
| <a name="input_enable_yace"></a> [enable_yace](#input_enable_yace)                                                                                           | deploy yet another cloudwatch exporter to fetch aws resources metrics                                                                                                                                                             | `bool`                                                                                                | `true`                                                     |    no    |
| <a name="input_external_dns"></a> [external_dns](#input_external_dns)                                                                                        | Using external DNS. A `subdomain` must also be specified if this value is true.                                                                                                                                                   | `bool`                                                                                                | `false`                                                    |    no    |
| <a name="input_extra_fqdn"></a> [extra_fqdn](#input_extra_fqdn)                                                                                              | Additional fqdn's must be in the same hosted zone as `domain_name`.                                                                                                                                                               | `list(string)`                                                                                        | `[]`                                                       |    no    |
| <a name="input_kms_key_alias"></a> [kms_key_alias](#input_kms_key_alias)                                                                                     | KMS key alias for AWS KMS Customer managed key.                                                                                                                                                                                   | `string`                                                                                              | `null`                                                     |    no    |
| <a name="input_kms_key_deletion_window"></a> [kms_key_deletion_window](#input_kms_key_deletion_window)                                                       | Duration in days to destroy the key after it is deleted. Must be between 7 and 30 days.                                                                                                                                           | `number`                                                                                              | `7`                                                        |    no    |
| <a name="input_kms_key_policy"></a> [kms_key_policy](#input_kms_key_policy)                                                                                  | The policy that will define the permissions for the kms key.                                                                                                                                                                      | `string`                                                                                              | `""`                                                       |    no    |
| <a name="input_kubernetes_alb_internet_facing"></a> [kubernetes_alb_internet_facing](#input_kubernetes_alb_internet_facing)                                  | Indicates whether or not the ALB controlled by the Amazon ALB ingress controller is internet-facing or internal.                                                                                                                  | `bool`                                                                                                | `true`                                                     |    no    |
| <a name="input_kubernetes_alb_subnets"></a> [kubernetes_alb_subnets](#input_kubernetes_alb_subnets)                                                          | List of subnet ID's the ALB will use for ingress traffic.                                                                                                                                                                         | `list(string)`                                                                                        | `[]`                                                       |    no    |
| <a name="input_kubernetes_instance_types"></a> [kubernetes_instance_types](#input_kubernetes_instance_types)                                                 | EC2 Instance type for primary node group.                                                                                                                                                                                         | `list(string)`                                                                                        | <pre>[<br> "m5.large"<br>]</pre>                           |    no    |
| <a name="input_kubernetes_map_accounts"></a> [kubernetes_map_accounts](#input_kubernetes_map_accounts)                                                       | Additional AWS account numbers to add to the aws-auth configmap.                                                                                                                                                                  | `list(string)`                                                                                        | `[]`                                                       |    no    |
| <a name="input_kubernetes_map_roles"></a> [kubernetes_map_roles](#input_kubernetes_map_roles)                                                                | Additional IAM roles to add to the aws-auth configmap.                                                                                                                                                                            | <pre>list(object({<br> rolearn = string<br> username = string<br> groups = list(string)<br> }))</pre> | `[]`                                                       |    no    |
| <a name="input_kubernetes_map_users"></a> [kubernetes_map_users](#input_kubernetes_map_users)                                                                | Additional IAM users to add to the aws-auth configmap.                                                                                                                                                                            | <pre>list(object({<br> userarn = string<br> username = string<br> groups = list(string)<br> }))</pre> | `[]`                                                       |    no    |
| <a name="input_kubernetes_node_count"></a> [kubernetes_node_count](#input_kubernetes_node_count)                                                             | Number of nodes                                                                                                                                                                                                                   | `number`                                                                                              | `2`                                                        |    no    |
| <a name="input_kubernetes_public_access"></a> [kubernetes_public_access](#input_kubernetes_public_access)                                                    | Indicates whether or not the Amazon EKS public API server endpoint is enabled.                                                                                                                                                    | `bool`                                                                                                | `false`                                                    |    no    |
| <a name="input_kubernetes_public_access_cidrs"></a> [kubernetes_public_access_cidrs](#input_kubernetes_public_access_cidrs)                                  | List of CIDR blocks which can access the Amazon EKS public API server endpoint.                                                                                                                                                   | `list(string)`                                                                                        | `[]`                                                       |    no    |
| <a name="input_license"></a> [license](#input_license)                                                                                                       | Weights & Biases license key.                                                                                                                                                                                                     | `string`                                                                                              | n/a                                                        |   yes    |
| <a name="input_namespace"></a> [namespace](#input_namespace)                                                                                                 | String used for prefix resources.                                                                                                                                                                                                 | `string`                                                                                              | n/a                                                        |   yes    |
| <a name="input_network_cidr"></a> [network_cidr](#input_network_cidr)                                                                                        | CIDR block for VPC.                                                                                                                                                                                                               | `string`                                                                                              | `"10.10.0.0/16"`                                           |    no    |
| <a name="input_network_database_subnet_cidrs"></a> [network_database_subnet_cidrs](#input_network_database_subnet_cidrs)                                     | List of private subnet CIDR ranges to create in VPC.                                                                                                                                                                              | `list(string)`                                                                                        | <pre>[<br> "10.10.20.0/24",<br> "10.10.21.0/24"<br>]</pre> |    no    |
| <a name="input_network_database_subnets"></a> [network_database_subnets](#input_network_database_subnets)                                                    | A list of the identities of the database subnetworks in which resources will be deployed.                                                                                                                                         | `list(string)`                                                                                        | `[]`                                                       |    no    |
| <a name="input_network_elasticache_subnet_cidrs"></a> [network_elasticache_subnet_cidrs](#input_network_elasticache_subnet_cidrs)                            | List of private subnet CIDR ranges to create in VPC.                                                                                                                                                                              | `list(string)`                                                                                        | <pre>[<br> "10.10.30.0/24",<br> "10.10.31.0/24"<br>]</pre> |    no    |
| <a name="input_network_elasticache_subnets"></a> [network_elasticache_subnets](#input_network_elasticache_subnets)                                           | A list of the identities of the subnetworks in which elasticache resources will be deployed.                                                                                                                                      | `list(string)`                                                                                        | `[]`                                                       |    no    |
| <a name="input_network_id"></a> [network_id](#input_network_id)                                                                                              | The identity of the VPC in which resources will be deployed.                                                                                                                                                                      | `string`                                                                                              | `""`                                                       |    no    |
| <a name="input_network_private_subnet_cidrs"></a> [network_private_subnet_cidrs](#input_network_private_subnet_cidrs)                                        | List of private subnet CIDR ranges to create in VPC.                                                                                                                                                                              | `list(string)`                                                                                        | <pre>[<br> "10.10.10.0/24",<br> "10.10.11.0/24"<br>]</pre> |    no    |
| <a name="input_network_private_subnets"></a> [network_private_subnets](#input_network_private_subnets)                                                       | A list of the identities of the private subnetworks in which resources will be deployed.                                                                                                                                          | `list(string)`                                                                                        | `[]`                                                       |    no    |
| <a name="input_network_public_subnet_cidrs"></a> [network_public_subnet_cidrs](#input_network_public_subnet_cidrs)                                           | List of private subnet CIDR ranges to create in VPC.                                                                                                                                                                              | `list(string)`                                                                                        | <pre>[<br> "10.10.0.0/24",<br> "10.10.1.0/24"<br>]</pre>   |    no    |
| <a name="input_network_public_subnets"></a> [network_public_subnets](#input_network_public_subnets)                                                          | A list of the identities of the public subnetworks in which resources will be deployed.                                                                                                                                           | `list(string)`                                                                                        | `[]`                                                       |    no    |
| <a name="input_other_wandb_env"></a> [other_wandb_env](#input_other_wandb_env)                                                                               | Extra environment variables for W&B                                                                                                                                                                                               | `map(any)`                                                                                            | `{}`                                                       |    no    |
| <a name="input_parquet_wandb_env"></a> [parquet_wandb_env](#input_parquet_wandb_env)                                                                         | Extra environment variables for W&B                                                                                                                                                                                               | `map(string)`                                                                                         | `{}`                                                       |    no    |
| <a name="input_private_link_allowed_account_ids"></a> [private_link_allowed_account_ids](#input_private_link_allowed_account_ids)                            | List of AWS account IDs allowed to access the VPC Endpoint Service                                                                                                                                                                | `list(string)`                                                                                        | `[]`                                                       |    no    |
| <a name="input_private_only_traffic"></a> [private_only_traffic](#input_private_only_traffic)                                                                | Enable private only traffic from customer private network                                                                                                                                                                         | `bool`                                                                                                | `false`                                                    |    no    |
| <a name="input_public_access"></a> [public_access](#input_public_access)                                                                                     | Is this instance accessable a public domain.                                                                                                                                                                                      | `bool`                                                                                                | `false`                                                    |    no    |
| <a name="input_size"></a> [size](#input_size)                                                                                                                | Deployment size                                                                                                                                                                                                                   | `string`                                                                                              | `null`                                                     |    no    |
| <a name="input_ssl_policy"></a> [ssl_policy](#input_ssl_policy)                                                                                              | SSL policy to use on ALB listener                                                                                                                                                                                                 | `string`                                                                                              | `"ELBSecurityPolicy-FS-1-2-Res-2020-10"`                   |    no    |
| <a name="input_subdomain"></a> [subdomain](#input_subdomain)                                                                                                 | Subdomain for accessing the Weights & Biases UI. Default creates record at Route53 Route.                                                                                                                                         | `string`                                                                                              | `null`                                                     |    no    |
| <a name="input_system_reserved_cpu_millicores"></a> [system_reserved_cpu_millicores](#input_system_reserved_cpu_millicores)                                  | (Optional) The amount of 'system-reserved' CPU millicores to pass to the kubelet. For example: 100. A value of -1 disables the flag.                                                                                              | `number`                                                                                              | `70`                                                       |    no    |
| <a name="input_system_reserved_ephemeral_megabytes"></a> [system_reserved_ephemeral_megabytes](#input_system_reserved_ephemeral_megabytes)                   | (Optional) The amount of 'system-reserved' ephemeral storage in megabytes to pass to the kubelet. For example: 1000. A value of -1 disables the flag.                                                                             | `number`                                                                                              | `750`                                                      |    no    |
| <a name="input_system_reserved_memory_megabytes"></a> [system_reserved_memory_megabytes](#input_system_reserved_memory_megabytes)                            | (Optional) The amount of 'system-reserved' memory in megabytes to pass to the kubelet. For example: 100. A value of -1 disables the flag.                                                                                         | `number`                                                                                              | `100`                                                      |    no    |
| <a name="input_system_reserved_pid"></a> [system_reserved_pid](#input_system_reserved_pid)                                                                   | (Optional) The amount of 'system-reserved' process ids [pid] to pass to the kubelet. For example: 1000. A value of -1 disables the flag.                                                                                          | `number`                                                                                              | `500`                                                      |    no    |
| <a name="input_use_internal_queue"></a> [use_internal_queue](#input_use_internal_queue)                                                                      | n/a                                                                                                                                                                                                                               | `bool`                                                                                                | `false`                                                    |    no    |
| <a name="input_weave_wandb_env"></a> [weave_wandb_env](#input_weave_wandb_env)                                                                               | Extra environment variables for W&B                                                                                                                                                                                               | `map(string)`                                                                                         | `{}`                                                       |    no    |
| <a name="input_yace_sa_name"></a> [yace_sa_name](#input_yace_sa_name)                                                                                        | n/a                                                                                                                                                                                                                               | `string`                                                                                              | `"wandb-yace"`                                             |    no    |
| <a name="input_zone_id"></a> [zone_id](#input_zone_id)                                                                                                       | Domain for creating the Weights & Biases subdomain on.                                                                                                                                                                            | `string`                                                                                              | n/a                                                        |   yes    |

## Outputs

| Name                                                                                                                       | Description                                                           |
| -------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------- |
| <a name="output_bucket_name"></a> [bucket_name](#output_bucket_name)                                                       | n/a                                                                   |
| <a name="output_bucket_queue_name"></a> [bucket_queue_name](#output_bucket_queue_name)                                     | n/a                                                                   |
| <a name="output_bucket_region"></a> [bucket_region](#output_bucket_region)                                                 | n/a                                                                   |
| <a name="output_cluster_id"></a> [cluster_id](#output_cluster_id)                                                          | n/a                                                                   |
| <a name="output_cluster_node_role"></a> [cluster_node_role](#output_cluster_node_role)                                     | n/a                                                                   |
| <a name="output_database_connection_string"></a> [database_connection_string](#output_database_connection_string)          | n/a                                                                   |
| <a name="output_database_instance_type"></a> [database_instance_type](#output_database_instance_type)                      | n/a                                                                   |
| <a name="output_database_password"></a> [database_password](#output_database_password)                                     | n/a                                                                   |
| <a name="output_database_username"></a> [database_username](#output_database_username)                                     | n/a                                                                   |
| <a name="output_eks_node_count"></a> [eks_node_count](#output_eks_node_count)                                              | n/a                                                                   |
| <a name="output_eks_node_instance_type"></a> [eks_node_instance_type](#output_eks_node_instance_type)                      | n/a                                                                   |
| <a name="output_elasticache_connection_string"></a> [elasticache_connection_string](#output_elasticache_connection_string) | n/a                                                                   |
| <a name="output_internal_app_port"></a> [internal_app_port](#output_internal_app_port)                                     | n/a                                                                   |
| <a name="output_kms_key_arn"></a> [kms_key_arn](#output_kms_key_arn)                                                       | The Amazon Resource Name of the KMS key used to encrypt data at rest. |
| <a name="output_network_id"></a> [network_id](#output_network_id)                                                          | The identity of the VPC in which resources are deployed.              |
| <a name="output_network_private_subnets"></a> [network_private_subnets](#output_network_private_subnets)                   | The identities of the private subnetworks deployed within the VPC.    |
| <a name="output_network_public_subnets"></a> [network_public_subnets](#output_network_public_subnets)                      | The identities of the public subnetworks deployed within the VPC.     |
| <a name="output_redis_instance_type"></a> [redis_instance_type](#output_redis_instance_type)                               | n/a                                                                   |
| <a name="output_standardized_size"></a> [standardized_size](#output_standardized_size)                                     | n/a                                                                   |
| <a name="output_url"></a> [url](#output_url)                                                                               | The URL to the W&B application                                        |

<!-- END_TF_DOCS -->

## Migrations

### Upgrading to Operator

See our upgrade guide [here](./docs/operator-migration/readme.md)

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

this can be donw by adding the following policy document.

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
        "kms:DescribeKey"
      ],
      "Resource": "*"
    }
```

### Upgrading from 2.x -> 3.x

- No changes required by you

### Upgrading from 1.x -> 2.x

- ~>4.0 version required for AWS Provider

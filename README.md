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

Available sizes are, `small`, `medium`, `large`, `xlarge`, and `xxlarge`. Default is `small`.

All the values set via `deployment-size.tf` can be overridden by setting the appropriate input variables.

- `kubernetes_instance_types` - The instance type for the EKS nodes
- `kubernetes_min_nodes_per_az` - The minimum number of nodes in each AZ for the EKS cluster
- `kubernetes_max_nodes_per_az` - The maximum number of nodes in each AZ for the EKS cluster
- `elasticache_node_type` - The instance type for the redis cluster
- `database_instance_class` - The instance type for the database

## Bring Your Own Bucket (BYOB)

We have added additional variable that make enabling BYOB easier to enable.
`bucket_permissions_mode` accepts 1 of 3 values;

- `strict` the default requires an explict list of the buckets for proper access, the same as byob before `7.3.0`.
- `restricted` makes use of the new variable `bucket_restricted_accounts` which is a list of AWS account Id's where the BYOBs can be hosted from. ex: `["1234567890", "1234876590"]`
- `public` enables access to any BYOB properly configured not present in the the calling account. Effectively this enables cross account s3 access to ANY aws s3 account.

> [!IMPORTANT]
> Enabling BYOB or cross-account reguardless of `bucket_permissions_mode` still requires a policy attached to that bucket to allowing the eks node role to perform s3 actions.
>
> To find out the role which needs to be allowed access to your BYOB go to bucket section of `https://YOUR_WANDB_DEPLOYMENT/console/settings/system` or see the output of the module `cluster_node_role`
>
> You can use the [Secure Storage Connector submodule](https://github.com/wandb/terraform-aws-wandb/tree/main/modules/secure_storage_connector) to create a bucket that allows access for the deployed cluster

## Examples

We have included documentation and reference examples for additional common
installation scenarios for Weights & Biases, as well as examples for supporting
resources that lack official modules.

- [Private Access Only](https://github.com/wandb/terraform-aws-wandb/tree/main/examples/private-access-only)
- [Private Existing Network](https://github.com/wandb/terraform-aws-wandb/tree/main/examples/private-existing-network)
- [Public External DNS](https://github.com/wandb/terraform-aws-wandb/tree/main/examples/public-dns-external)
- [Public Route 53 DNS](https://github.com/wandb/terraform-aws-wandb/tree/main/examples/public-dns-with-route53)

### A note on updating EKS cluster version

Users can update the EKS cluster version to the latest version offered by AWS using the input variable `eks_cluster_version`. Cluster and nodegroup version updates can only be done in increments of one minor version at a time, so multi-version upgrades must be executed step-wise.

#### Recommended pattern: pre-roll addons first, then the cluster

Each minor version bump should be a two-apply sequence so that addon and control-plane changes are isolated:

1. **Pre-roll addons for the target version.** Set `eks_addons_preroll_version` to the _next_ minor version while leaving `eks_cluster_version` at the _current_ version. `terraform apply`. The cluster stays put; preroll-eligible addons are pulled from `local.eks_addons_preroll_versions` in [`modules/app_eks/add-ons.tf`](modules/app_eks/add-ons.tf). kube-proxy and metrics-server are intentionally excluded from preroll — kube-proxy is locked to the cluster minor by Kubernetes' version-skew policy, and AWS gates `metrics-server` v0.8.x lines on cluster K8s version.
2. **Bump the cluster.** Set `eks_cluster_version` to the same target version and unset `eks_addons_preroll_version`. `terraform apply`. The control plane and node group move up; preroll-eligible addons are already there, kube-proxy / metrics-server roll forward with the cluster.

Repeat for each subsequent minor version. For example, going from `1.30` → `1.32`:

| Step | `eks_cluster_version` | `eks_addons_preroll_version` | Effect                                                                                          |
| :--- | :-------------------- | :--------------------------- | :---------------------------------------------------------------------------------------------- |
| 1    | `1.30`                | `1.31`                       | Preroll-eligible addons move to 1.31 defaults; cluster, kube-proxy, metrics-server stay on 1.30 |
| 2    | `1.31`                | `null`                       | Cluster moves to 1.31; kube-proxy / metrics-server roll forward                                 |
| 3    | `1.31`                | `1.32`                       | Preroll-eligible addons move to 1.32 defaults; cluster stays on 1.31                            |
| 4    | `1.32`                | `null`                       | Cluster moves to 1.32                                                                           |

You can still pin individual addon versions explicitly via the per-addon `eks_addon_*_version` overrides; those win over both the preroll table and the cluster-version default.

Upgrades must be executed in step-wise fashion from one version to the next. You cannot skip versions when upgrading EKS.

<!-- BEGIN_TF_DOCS -->

## Requirements

| Name                                                                        | Version |
| --------------------------------------------------------------------------- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform)    | ~> 1.9  |
| <a name="requirement_aws"></a> [aws](#requirement_aws)                      | ~> 5.95 |
| <a name="requirement_helm"></a> [helm](#requirement_helm)                   | < 3.0.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement_kubernetes) | ~> 2.23 |
| <a name="requirement_null"></a> [null](#requirement_null)                   | ~> 3.0  |
| <a name="requirement_time"></a> [time](#requirement_time)                   | ~> 0.13 |

## Providers

| Name                                                | Version |
| --------------------------------------------------- | ------- |
| <a name="provider_aws"></a> [aws](#provider_aws)    | 5.100.0 |
| <a name="provider_null"></a> [null](#provider_null) | 3.2.4   |
| <a name="provider_time"></a> [time](#provider_time) | 0.13.1  |

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
| <a name="module_wandb"></a> [wandb](#module_wandb)                      | wandb/wandb/helm              | 3.0.0   |

## Resources

| Name                                                                                                                   | Type        |
| ---------------------------------------------------------------------------------------------------------------------- | ----------- |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region)            | data source |
| [aws_s3_bucket.file_storage](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_bucket) | data source |
| [aws_sqs_queue.file_storage](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/sqs_queue) | data source |

## Inputs

| Name                                                                                                                                                                  | Description                                                                                                                                                                                                                                                                                                   | Type                                                                                                      | Default                                                       | Required |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------- | :------: |
| <a name="input_acm_certificate_arn"></a> [acm_certificate_arn](#input_acm_certificate_arn)                                                                            | The ARN of an existing ACM certificate.                                                                                                                                                                                                                                                                       | `string`                                                                                                  | `null`                                                        |    no    |
| <a name="input_allowed_inbound_cidr"></a> [allowed_inbound_cidr](#input_allowed_inbound_cidr)                                                                         | CIDRs allowed to access wandb-server.                                                                                                                                                                                                                                                                         | `list(string)`                                                                                            | n/a                                                           |   yes    |
| <a name="input_allowed_inbound_ipv6_cidr"></a> [allowed_inbound_ipv6_cidr](#input_allowed_inbound_ipv6_cidr)                                                          | CIDRs allowed to access wandb-server.                                                                                                                                                                                                                                                                         | `list(string)`                                                                                            | n/a                                                           |   yes    |
| <a name="input_allowed_private_endpoint_cidr"></a> [allowed_private_endpoint_cidr](#input_allowed_private_endpoint_cidr)                                              | Private CIDRs allowed to access wandb-server.                                                                                                                                                                                                                                                                 | `list(string)`                                                                                            | `[]`                                                          |    no    |
| <a name="input_aws_loadbalancer_controller_image_repository"></a> [aws_loadbalancer_controller_image_repository](#input_aws_loadbalancer_controller_image_repository) | The image repository of the aws-loadbalancer-controller to deploy.                                                                                                                                                                                                                                            | `string`                                                                                                  | `"public.ecr.aws/eks/aws-load-balancer-controller"`           |    no    |
| <a name="input_aws_loadbalancer_controller_image_tag"></a> [aws_loadbalancer_controller_image_tag](#input_aws_loadbalancer_controller_image_tag)                      | The tag of the aws-loadbalancer-controller to deploy.                                                                                                                                                                                                                                                         | `string`                                                                                                  | `null`                                                        |    no    |
| <a name="input_aws_loadbalancer_controller_tags"></a> [aws_loadbalancer_controller_tags](#input_aws_loadbalancer_controller_tags)                                     | (Optional) A map of AWS tags to apply to all resources managed by the load balancer controller                                                                                                                                                                                                                | `map(string)`                                                                                             | `{}`                                                          |    no    |
| <a name="input_bucket_kms_key_arn"></a> [bucket_kms_key_arn](#input_bucket_kms_key_arn)                                                                               | n/a                                                                                                                                                                                                                                                                                                           | `string`                                                                                                  | `""`                                                          |    no    |
| <a name="input_bucket_name"></a> [bucket_name](#input_bucket_name)                                                                                                    | ######################################### External Bucket # ######################################### Most users will not need these settings. They are ment for users who want a bucket and sqs that are in a different account.                                                                             | `string`                                                                                                  | `""`                                                          |    no    |
| <a name="input_bucket_path"></a> [bucket_path](#input_bucket_path)                                                                                                    | path of where to store data for the instance-level bucket                                                                                                                                                                                                                                                     | `string`                                                                                                  | `""`                                                          |    no    |
| <a name="input_bucket_permissions_mode"></a> [bucket_permissions_mode](#input_bucket_permissions_mode)                                                                | Defines the bucket permissions mode, which can be one of: strict, restricted, or public.                                                                                                                                                                                                                      | `string`                                                                                                  | `"strict"`                                                    |    no    |
| <a name="input_bucket_restricted_accounts"></a> [bucket_restricted_accounts](#input_bucket_restricted_accounts)                                                       | List of allowed accounts when 'bucket_permissions_mode' is 'restricted'.                                                                                                                                                                                                                                      | `list(string)`                                                                                            | `[]`                                                          |    no    |
| <a name="input_clickhouse_endpoint_service_id"></a> [clickhouse_endpoint_service_id](#input_clickhouse_endpoint_service_id)                                           | The service ID of the VPC endpoint service for Clickhouse                                                                                                                                                                                                                                                     | `string`                                                                                                  | `""`                                                          |    no    |
| <a name="input_cluster_autoscaler_image_repository"></a> [cluster_autoscaler_image_repository](#input_cluster_autoscaler_image_repository)                            | The image repository of the cluster-autoscaler to deploy.                                                                                                                                                                                                                                                     | `string`                                                                                                  | `"registry.k8s.io/autoscaling/cluster-autoscaler"`            |    no    |
| <a name="input_cluster_autoscaler_image_tag"></a> [cluster_autoscaler_image_tag](#input_cluster_autoscaler_image_tag)                                                 | The tag of the cluster-autoscaler to deploy.                                                                                                                                                                                                                                                                  | `string`                                                                                                  | `null`                                                        |    no    |
| <a name="input_controller_image_tag"></a> [controller_image_tag](#input_controller_image_tag)                                                                         | Tag of the controller image to deploy                                                                                                                                                                                                                                                                         | `string`                                                                                                  | `"1.20.0"`                                                    |    no    |
| <a name="input_create_elasticache"></a> [create_elasticache](#input_create_elasticache)                                                                               | Boolean indicating whether to provision an elasticache instance (true) or not (false).                                                                                                                                                                                                                        | `bool`                                                                                                    | `true`                                                        |    no    |
| <a name="input_create_vpc"></a> [create_vpc](#input_create_vpc)                                                                                                       | Boolean indicating whether to deploy a VPC (true) or not (false).                                                                                                                                                                                                                                             | `bool`                                                                                                    | `true`                                                        |    no    |
| <a name="input_custom_domain_filter"></a> [custom_domain_filter](#input_custom_domain_filter)                                                                         | A custom domain filter to be used by external-dns instead of the default FQDN. If not set, the local FQDN is used.                                                                                                                                                                                            | `string`                                                                                                  | `null`                                                        |    no    |
| <a name="input_database_engine_version"></a> [database_engine_version](#input_database_engine_version)                                                                | Version for MySQL Aurora                                                                                                                                                                                                                                                                                      | `string`                                                                                                  | `"8.0"`                                                       |    no    |
| <a name="input_database_instance_class"></a> [database_instance_class](#input_database_instance_class)                                                                | Instance type to use by database master instance. Defaults to null and value from deployment-size.tf is used                                                                                                                                                                                                  | `string`                                                                                                  | `null`                                                        |    no    |
| <a name="input_database_kms_key_arn"></a> [database_kms_key_arn](#input_database_kms_key_arn)                                                                         | n/a                                                                                                                                                                                                                                                                                                           | `string`                                                                                                  | `""`                                                          |    no    |
| <a name="input_database_master_username"></a> [database_master_username](#input_database_master_username)                                                             | Specifies the master_username value to set for the database                                                                                                                                                                                                                                                   | `string`                                                                                                  | `"wandb"`                                                     |    no    |
| <a name="input_database_name"></a> [database_name](#input_database_name)                                                                                              | Specifies the name of the database                                                                                                                                                                                                                                                                            | `string`                                                                                                  | `"wandb_local"`                                               |    no    |
| <a name="input_database_performance_insights_kms_key_arn"></a> [database_performance_insights_kms_key_arn](#input_database_performance_insights_kms_key_arn)          | Specifies an existing KMS key ARN to encrypt the performance insights data if performance_insights_enabled is was enabled out of band                                                                                                                                                                         | `string`                                                                                                  | `""`                                                          |    no    |
| <a name="input_database_snapshot_identifier"></a> [database_snapshot_identifier](#input_database_snapshot_identifier)                                                 | Specifies whether or not to create this cluster from a snapshot. You can use either the name or ARN when specifying a DB cluster snapshot, or the ARN when specifying a DB snapshot                                                                                                                           | `string`                                                                                                  | `null`                                                        |    no    |
| <a name="input_database_sort_buffer_size"></a> [database_sort_buffer_size](#input_database_sort_buffer_size)                                                          | Specifies the sort_buffer_size value to set for the database                                                                                                                                                                                                                                                  | `number`                                                                                                  | `67108864`                                                    |    no    |
| <a name="input_deletion_protection"></a> [deletion_protection](#input_deletion_protection)                                                                            | If the instance should have deletion protection enabled. The database / S3 can't be deleted when this value is set to `true`.                                                                                                                                                                                 | `bool`                                                                                                    | `true`                                                        |    no    |
| <a name="input_domain_name"></a> [domain_name](#input_domain_name)                                                                                                    | Domain for accessing the Weights & Biases UI.                                                                                                                                                                                                                                                                 | `string`                                                                                                  | n/a                                                           |   yes    |
| <a name="input_eks_addon_coredns_version"></a> [eks_addon_coredns_version](#input_eks_addon_coredns_version)                                                          | Override for the CoreDNS addon version. When null, the version is looked up by var.eks_cluster_version (or var.eks_addons_upgrade_cluster_version when that override is set) in local.eks_addon_default_versions in modules/app_eks/add-ons.tf.                                                               | `string`                                                                                                  | `null`                                                        |    no    |
| <a name="input_eks_addon_ebs_csi_driver_version"></a> [eks_addon_ebs_csi_driver_version](#input_eks_addon_ebs_csi_driver_version)                                     | Override for the EBS CSI driver version. When null, the version is looked up by var.eks_cluster_version (or var.eks_addons_upgrade_cluster_version when that override is set) in local.eks_addon_default_versions in modules/app_eks/add-ons.tf.                                                              | `string`                                                                                                  | `null`                                                        |    no    |
| <a name="input_eks_addon_efs_csi_driver_version"></a> [eks_addon_efs_csi_driver_version](#input_eks_addon_efs_csi_driver_version)                                     | Override for the EFS CSI driver version. When null, the version is looked up by var.eks_cluster_version (or var.eks_addons_upgrade_cluster_version when that override is set) in local.eks_addon_default_versions in modules/app_eks/add-ons.tf.                                                              | `string`                                                                                                  | `null`                                                        |    no    |
| <a name="input_eks_addon_kube_proxy_version"></a> [eks_addon_kube_proxy_version](#input_eks_addon_kube_proxy_version)                                                 | Override for the kube-proxy addon version. When null, the version is looked up by var.eks_cluster_version (or var.eks_addons_upgrade_cluster_version when that override is set) in local.eks_addon_default_versions in modules/app_eks/add-ons.tf.                                                            | `string`                                                                                                  | `null`                                                        |    no    |
| <a name="input_eks_addon_metrics_server_version"></a> [eks_addon_metrics_server_version](#input_eks_addon_metrics_server_version)                                     | Override for the metrics-server addon version. When null, the version is looked up by var.eks_cluster_version (or var.eks_addons_upgrade_cluster_version when that override is set) in local.eks_addon_default_versions in modules/app_eks/add-ons.tf.                                                        | `string`                                                                                                  | `null`                                                        |    no    |
| <a name="input_eks_addon_vpc_cni_version"></a> [eks_addon_vpc_cni_version](#input_eks_addon_vpc_cni_version)                                                          | Override for the VPC CNI addon version. When null, the version is looked up by var.eks_cluster_version (or var.eks_addons_upgrade_cluster_version when that override is set) in local.eks_addon_default_versions in modules/app_eks/add-ons.tf.                                                               | `string`                                                                                                  | `null`                                                        |    no    |
| <a name="input_eks_addons_preroll_version"></a> [eks_addons_preroll_version](#input_eks_addons_preroll_version)                                                       | Optional Kubernetes minor version to roll preroll-eligible addons toward, while the cluster itself stays on var.eks_cluster_version. See local.eks_addons_preroll_versions in modules/app_eks/add-ons.tf for the addons covered. kube-proxy and metrics-server are intentionally excluded from preroll.       | `string`                                                                                                  | `null`                                                        |    no    |
| <a name="input_eks_cluster_tags"></a> [eks_cluster_tags](#input_eks_cluster_tags)                                                                                     | A map of AWS tags to apply to all resources managed by the EKS cluster                                                                                                                                                                                                                                        | `map(string)`                                                                                             | `{}`                                                          |    no    |
| <a name="input_eks_cluster_version"></a> [eks_cluster_version](#input_eks_cluster_version)                                                                            | EKS cluster kubernetes version                                                                                                                                                                                                                                                                                | `string`                                                                                                  | n/a                                                           |   yes    |
| <a name="input_eks_policy_arns"></a> [eks_policy_arns](#input_eks_policy_arns)                                                                                        | Additional IAM policy to apply to the EKS cluster                                                                                                                                                                                                                                                             | `list(string)`                                                                                            | `[]`                                                          |    no    |
| <a name="input_elasticache_node_type"></a> [elasticache_node_type](#input_elasticache_node_type)                                                                      | The type of the redis cache node to deploy. Defaults to null and value from deployment-size.tf is used                                                                                                                                                                                                        | `string`                                                                                                  | `null`                                                        |    no    |
| <a name="input_enable_clickhouse"></a> [enable_clickhouse](#input_enable_clickhouse)                                                                                  | Provision clickhouse resources                                                                                                                                                                                                                                                                                | `bool`                                                                                                    | `false`                                                       |    no    |
| <a name="input_enable_flow_log"></a> [enable_flow_log](#input_enable_flow_log)                                                                                        | Controls whether VPC Flow Logs are enabled                                                                                                                                                                                                                                                                    | `bool`                                                                                                    | `false`                                                       |    no    |
| <a name="input_enable_helm_operator"></a> [enable_helm_operator](#input_enable_helm_operator)                                                                         | Enable or disable applying and releasing W&B Operator chart                                                                                                                                                                                                                                                   | `bool`                                                                                                    | `true`                                                        |    no    |
| <a name="input_enable_helm_wandb"></a> [enable_helm_wandb](#input_enable_helm_wandb)                                                                                  | Enable or disable applying and releasing CR chart                                                                                                                                                                                                                                                             | `bool`                                                                                                    | `true`                                                        |    no    |
| <a name="input_enable_s3_https_only"></a> [enable_s3_https_only](#input_enable_s3_https_only)                                                                         | Controls whether HTTPS-only is enabled for s3 buckets                                                                                                                                                                                                                                                         | `bool`                                                                                                    | `false`                                                       |    no    |
| <a name="input_enable_yace"></a> [enable_yace](#input_enable_yace)                                                                                                    | deploy yet another cloudwatch exporter to fetch aws resources metrics                                                                                                                                                                                                                                         | `bool`                                                                                                    | `true`                                                        |    no    |
| <a name="input_external_dns"></a> [external_dns](#input_external_dns)                                                                                                 | Using external DNS. A `subdomain` must also be specified if this value is true.                                                                                                                                                                                                                               | `bool`                                                                                                    | `false`                                                       |    no    |
| <a name="input_external_dns_image_repository"></a> [external_dns_image_repository](#input_external_dns_image_repository)                                              | The image repository of the external-dns to deploy.                                                                                                                                                                                                                                                           | `string`                                                                                                  | `"registry.k8s.io/external-dns/external-dns"`                 |    no    |
| <a name="input_external_dns_image_tag"></a> [external_dns_image_tag](#input_external_dns_image_tag)                                                                   | The tag of the external-dns to deploy.                                                                                                                                                                                                                                                                        | `string`                                                                                                  | `null`                                                        |    no    |
| <a name="input_external_redis_host"></a> [external_redis_host](#input_external_redis_host)                                                                            | host for the redis instance created externally                                                                                                                                                                                                                                                                | `string`                                                                                                  | `null`                                                        |    no    |
| <a name="input_external_redis_params"></a> [external_redis_params](#input_external_redis_params)                                                                      | queryVar params for redis instance created externally                                                                                                                                                                                                                                                         | `object({})`                                                                                              | `null`                                                        |    no    |
| <a name="input_external_redis_port"></a> [external_redis_port](#input_external_redis_port)                                                                            | port for the redis instance created externally                                                                                                                                                                                                                                                                | `string`                                                                                                  | `null`                                                        |    no    |
| <a name="input_extra_fqdn"></a> [extra_fqdn](#input_extra_fqdn)                                                                                                       | Additional fqdn's must be in the same hosted zone as `domain_name`.                                                                                                                                                                                                                                           | `list(string)`                                                                                            | `[]`                                                          |    no    |
| <a name="input_k8s_namespace"></a> [k8s_namespace](#input_k8s_namespace)                                                                                              | The Kubernetes namespace where W&B resources will be deployed                                                                                                                                                                                                                                                 | `string`                                                                                                  | `"default"`                                                   |    no    |
| <a name="input_keep_flow_log_bucket"></a> [keep_flow_log_bucket](#input_keep_flow_log_bucket)                                                                         | Controls whether S3 bucket storing VPC Flow Logs will be kept                                                                                                                                                                                                                                                 | `bool`                                                                                                    | `true`                                                        |    no    |
| <a name="input_kms_clickhouse_key_alias"></a> [kms_clickhouse_key_alias](#input_kms_clickhouse_key_alias)                                                             | KMS key alias for AWS KMS Customer managed key used by Clickhouse CMEK.                                                                                                                                                                                                                                       | `string`                                                                                                  | `null`                                                        |    no    |
| <a name="input_kms_clickhouse_key_policy"></a> [kms_clickhouse_key_policy](#input_kms_clickhouse_key_policy)                                                          | The policy that will define the permissions for the clickhouse kms key.                                                                                                                                                                                                                                       | `string`                                                                                                  | `""`                                                          |    no    |
| <a name="input_kms_key_alias"></a> [kms_key_alias](#input_kms_key_alias)                                                                                              | KMS key alias for AWS KMS Customer managed key.                                                                                                                                                                                                                                                               | `string`                                                                                                  | `null`                                                        |    no    |
| <a name="input_kms_key_deletion_window"></a> [kms_key_deletion_window](#input_kms_key_deletion_window)                                                                | Duration in days to destroy the key after it is deleted. Must be between 7 and 30 days.                                                                                                                                                                                                                       | `number`                                                                                                  | `7`                                                           |    no    |
| <a name="input_kms_key_policy"></a> [kms_key_policy](#input_kms_key_policy)                                                                                           | The policy that will define the permissions for the kms key.                                                                                                                                                                                                                                                  | `string`                                                                                                  | `""`                                                          |    no    |
| <a name="input_kms_key_policy_administrator_arn"></a> [kms_key_policy_administrator_arn](#input_kms_key_policy_administrator_arn)                                     | The principal that will be allowed to manage the kms key.                                                                                                                                                                                                                                                     | `string`                                                                                                  | `""`                                                          |    no    |
| <a name="input_kubernetes_alb_internet_facing"></a> [kubernetes_alb_internet_facing](#input_kubernetes_alb_internet_facing)                                           | Indicates whether or not the ALB controlled by the Amazon ALB ingress controller is internet-facing or internal.                                                                                                                                                                                              | `bool`                                                                                                    | `true`                                                        |    no    |
| <a name="input_kubernetes_alb_subnets"></a> [kubernetes_alb_subnets](#input_kubernetes_alb_subnets)                                                                   | List of subnet ID's the ALB will use for ingress traffic.                                                                                                                                                                                                                                                     | `list(string)`                                                                                            | `[]`                                                          |    no    |
| <a name="input_kubernetes_instance_types"></a> [kubernetes_instance_types](#input_kubernetes_instance_types)                                                          | EC2 Instance type for primary node group. Defaults to null and value from deployment-size.tf is used                                                                                                                                                                                                          | `list(string)`                                                                                            | `null`                                                        |    no    |
| <a name="input_kubernetes_map_accounts"></a> [kubernetes_map_accounts](#input_kubernetes_map_accounts)                                                                | REMOVED. AWS account numbers for the aws-auth ConfigMap. EKS module v20 uses access entries, which require a per-principal ARN — account-wide trust is no longer expressible. See docs/upgrade-eks-20.md for migration paths. The variable is retained as a tripwire and will be removed in a future release. | `list(string)`                                                                                            | `[]`                                                          |    no    |
| <a name="input_kubernetes_map_roles"></a> [kubernetes_map_roles](#input_kubernetes_map_roles)                                                                         | Additional IAM roles to add to the aws-auth configmap.                                                                                                                                                                                                                                                        | <pre>list(object({<br/> rolearn = string<br/> username = string<br/> groups = list(string)<br/> }))</pre> | `[]`                                                          |    no    |
| <a name="input_kubernetes_map_users"></a> [kubernetes_map_users](#input_kubernetes_map_users)                                                                         | Additional IAM users to add to the aws-auth configmap.                                                                                                                                                                                                                                                        | <pre>list(object({<br/> userarn = string<br/> username = string<br/> groups = list(string)<br/> }))</pre> | `[]`                                                          |    no    |
| <a name="input_kubernetes_max_nodes_per_az"></a> [kubernetes_max_nodes_per_az](#input_kubernetes_max_nodes_per_az)                                                    | Maximum number of nodes for the EKS cluster. Defaults to null and value from deployment-size.tf is used                                                                                                                                                                                                       | `number`                                                                                                  | `null`                                                        |    no    |
| <a name="input_kubernetes_min_nodes_per_az"></a> [kubernetes_min_nodes_per_az](#input_kubernetes_min_nodes_per_az)                                                    | Minimum number of nodes for the EKS cluster. Defaults to null and value from deployment-size.tf is used                                                                                                                                                                                                       | `number`                                                                                                  | `null`                                                        |    no    |
| <a name="input_kubernetes_node_disk_size_gb"></a> [kubernetes_node_disk_size_gb](#input_kubernetes_node_disk_size_gb)                                                 | Size of the node root volume in GB.                                                                                                                                                                                                                                                                           | `number`                                                                                                  | `null`                                                        |    no    |
| <a name="input_kubernetes_public_access"></a> [kubernetes_public_access](#input_kubernetes_public_access)                                                             | Indicates whether or not the Amazon EKS public API server endpoint is enabled.                                                                                                                                                                                                                                | `bool`                                                                                                    | `false`                                                       |    no    |
| <a name="input_kubernetes_public_access_cidrs"></a> [kubernetes_public_access_cidrs](#input_kubernetes_public_access_cidrs)                                           | List of CIDR blocks which can access the Amazon EKS public API server endpoint.                                                                                                                                                                                                                               | `list(string)`                                                                                            | `[]`                                                          |    no    |
| <a name="input_license"></a> [license](#input_license)                                                                                                                | Weights & Biases license key.                                                                                                                                                                                                                                                                                 | `string`                                                                                                  | n/a                                                           |   yes    |
| <a name="input_namespace"></a> [namespace](#input_namespace)                                                                                                          | String used for prefix resources.                                                                                                                                                                                                                                                                             | `string`                                                                                                  | n/a                                                           |   yes    |
| <a name="input_network_cidr"></a> [network_cidr](#input_network_cidr)                                                                                                 | CIDR block for VPC.                                                                                                                                                                                                                                                                                           | `string`                                                                                                  | `"10.10.0.0/16"`                                              |    no    |
| <a name="input_network_database_subnet_cidrs"></a> [network_database_subnet_cidrs](#input_network_database_subnet_cidrs)                                              | List of private subnet CIDR ranges to create in VPC.                                                                                                                                                                                                                                                          | `list(string)`                                                                                            | <pre>[<br/> "10.10.20.0/24",<br/> "10.10.21.0/24"<br/>]</pre> |    no    |
| <a name="input_network_database_subnets"></a> [network_database_subnets](#input_network_database_subnets)                                                             | A list of the identities of the database subnetworks in which resources will be deployed.                                                                                                                                                                                                                     | `list(string)`                                                                                            | `[]`                                                          |    no    |
| <a name="input_network_elasticache_subnet_cidrs"></a> [network_elasticache_subnet_cidrs](#input_network_elasticache_subnet_cidrs)                                     | List of private subnet CIDR ranges to create in VPC.                                                                                                                                                                                                                                                          | `list(string)`                                                                                            | <pre>[<br/> "10.10.30.0/24",<br/> "10.10.31.0/24"<br/>]</pre> |    no    |
| <a name="input_network_elasticache_subnets"></a> [network_elasticache_subnets](#input_network_elasticache_subnets)                                                    | A list of the identities of the subnetworks in which elasticache resources will be deployed.                                                                                                                                                                                                                  | `list(string)`                                                                                            | `[]`                                                          |    no    |
| <a name="input_network_id"></a> [network_id](#input_network_id)                                                                                                       | The identity of the VPC in which resources will be deployed.                                                                                                                                                                                                                                                  | `string`                                                                                                  | `""`                                                          |    no    |
| <a name="input_network_private_subnet_cidrs"></a> [network_private_subnet_cidrs](#input_network_private_subnet_cidrs)                                                 | List of private subnet CIDR ranges to create in VPC.                                                                                                                                                                                                                                                          | `list(string)`                                                                                            | <pre>[<br/> "10.10.10.0/24",<br/> "10.10.11.0/24"<br/>]</pre> |    no    |
| <a name="input_network_private_subnets"></a> [network_private_subnets](#input_network_private_subnets)                                                                | A list of the identities of the private subnetworks in which resources will be deployed.                                                                                                                                                                                                                      | `list(string)`                                                                                            | `[]`                                                          |    no    |
| <a name="input_network_public_subnet_cidrs"></a> [network_public_subnet_cidrs](#input_network_public_subnet_cidrs)                                                    | List of private subnet CIDR ranges to create in VPC.                                                                                                                                                                                                                                                          | `list(string)`                                                                                            | <pre>[<br/> "10.10.0.0/24",<br/> "10.10.1.0/24"<br/>]</pre>   |    no    |
| <a name="input_operator_chart_version"></a> [operator_chart_version](#input_operator_chart_version)                                                                   | Version of the operator chart to deploy                                                                                                                                                                                                                                                                       | `string`                                                                                                  | `"1.4.2"`                                                     |    no    |
| <a name="input_other_wandb_env"></a> [other_wandb_env](#input_other_wandb_env)                                                                                        | Extra environment variables for W&B                                                                                                                                                                                                                                                                           | `map(any)`                                                                                                | `{}`                                                          |    no    |
| <a name="input_parquet_wandb_env"></a> [parquet_wandb_env](#input_parquet_wandb_env)                                                                                  | Extra environment variables for W&B                                                                                                                                                                                                                                                                           | `map(string)`                                                                                             | `{}`                                                          |    no    |
| <a name="input_preserve_aws_auth_configmap"></a> [preserve_aws_auth_configmap](#input_preserve_aws_auth_configmap)                                                    | v17 -> v20 in-place upgrade transition flag. See modules/app_eks/aws_auth_legacy.tf and docs/upgrade-eks-20.md.                                                                                                                                                                                               | `bool`                                                                                                    | `false`                                                       |    no    |
| <a name="input_private_link_allowed_account_ids"></a> [private_link_allowed_account_ids](#input_private_link_allowed_account_ids)                                     | List of AWS account IDs allowed to access the VPC Endpoint Service                                                                                                                                                                                                                                            | `list(string)`                                                                                            | `[]`                                                          |    no    |
| <a name="input_private_only_traffic"></a> [private_only_traffic](#input_private_only_traffic)                                                                         | Enable private only traffic from customer private network                                                                                                                                                                                                                                                     | `bool`                                                                                                    | `false`                                                       |    no    |
| <a name="input_public_access"></a> [public_access](#input_public_access)                                                                                              | Is this instance accessable a public domain.                                                                                                                                                                                                                                                                  | `bool`                                                                                                    | `false`                                                       |    no    |
| <a name="input_size"></a> [size](#input_size)                                                                                                                         | Deployment size for the instance                                                                                                                                                                                                                                                                              | `string`                                                                                                  | `"small"`                                                     |    no    |
| <a name="input_subdomain"></a> [subdomain](#input_subdomain)                                                                                                          | Subdomain for accessing the Weights & Biases UI. Default creates record at Route53 Route.                                                                                                                                                                                                                     | `string`                                                                                                  | `null`                                                        |    no    |
| <a name="input_system_reserved_cpu_millicores"></a> [system_reserved_cpu_millicores](#input_system_reserved_cpu_millicores)                                           | (Optional) The amount of 'system-reserved' CPU millicores to pass to the kubelet. For example: 100. A value of -1 disables the flag.                                                                                                                                                                          | `number`                                                                                                  | `70`                                                          |    no    |
| <a name="input_system_reserved_ephemeral_megabytes"></a> [system_reserved_ephemeral_megabytes](#input_system_reserved_ephemeral_megabytes)                            | (Optional) The amount of 'system-reserved' ephemeral storage in megabytes to pass to the kubelet. For example: 1000. A value of -1 disables the flag.                                                                                                                                                         | `number`                                                                                                  | `750`                                                         |    no    |
| <a name="input_system_reserved_memory_megabytes"></a> [system_reserved_memory_megabytes](#input_system_reserved_memory_megabytes)                                     | (Optional) The amount of 'system-reserved' memory in megabytes to pass to the kubelet. For example: 100. A value of -1 disables the flag.                                                                                                                                                                     | `number`                                                                                                  | `100`                                                         |    no    |
| <a name="input_system_reserved_pid"></a> [system_reserved_pid](#input_system_reserved_pid)                                                                            | (Optional) The amount of 'system-reserved' process ids [pid] to pass to the kubelet. For example: 1000. A value of -1 disables the flag.                                                                                                                                                                      | `number`                                                                                                  | `500`                                                         |    no    |
| <a name="input_use_chainguard_redis"></a> [use_chainguard_redis](#input_use_chainguard_redis)                                                                         | Whether CHAINGUARD redis is deployed in the cluster                                                                                                                                                                                                                                                           | `bool`                                                                                                    | `false`                                                       |    no    |
| <a name="input_use_ctrlplane_redis"></a> [use_ctrlplane_redis](#input_use_ctrlplane_redis)                                                                            | Whether redis is deployed in the cluster via ctrlplane                                                                                                                                                                                                                                                        | `bool`                                                                                                    | `false`                                                       |    no    |
| <a name="input_use_external_redis"></a> [use_external_redis](#input_use_external_redis)                                                                               | Boolean indicating whether to use the redis instance created externally                                                                                                                                                                                                                                       | `bool`                                                                                                    | `false`                                                       |    no    |
| <a name="input_use_internal_queue"></a> [use_internal_queue](#input_use_internal_queue)                                                                               | n/a                                                                                                                                                                                                                                                                                                           | `bool`                                                                                                    | `false`                                                       |    no    |
| <a name="input_weave_wandb_env"></a> [weave_wandb_env](#input_weave_wandb_env)                                                                                        | Extra environment variables for W&B                                                                                                                                                                                                                                                                           | `map(string)`                                                                                             | `{}`                                                          |    no    |
| <a name="input_yace_sa_name"></a> [yace_sa_name](#input_yace_sa_name)                                                                                                 | n/a                                                                                                                                                                                                                                                                                                           | `string`                                                                                                  | `"wandb-yace"`                                                |    no    |
| <a name="input_zone_id"></a> [zone_id](#input_zone_id)                                                                                                                | Domain for creating the Weights & Biases subdomain on.                                                                                                                                                                                                                                                        | `string`                                                                                                  | n/a                                                           |   yes    |

## Outputs

| Name                                                                                                                                      | Description                                                                                                                                                                                      |
| ----------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| <a name="output_bucket_name"></a> [bucket_name](#output_bucket_name)                                                                      | n/a                                                                                                                                                                                              |
| <a name="output_bucket_path"></a> [bucket_path](#output_bucket_path)                                                                      | n/a                                                                                                                                                                                              |
| <a name="output_bucket_queue_name"></a> [bucket_queue_name](#output_bucket_queue_name)                                                    | n/a                                                                                                                                                                                              |
| <a name="output_bucket_region"></a> [bucket_region](#output_bucket_region)                                                                | n/a                                                                                                                                                                                              |
| <a name="output_cluster_certificate_authority_data"></a> [cluster_certificate_authority_data](#output_cluster_certificate_authority_data) | n/a                                                                                                                                                                                              |
| <a name="output_cluster_endpoint"></a> [cluster_endpoint](#output_cluster_endpoint)                                                       | Surfaced so callers can configure kubernetes/helm providers directly from module outputs instead of `data "aws_eks_cluster"`. See modules/app_eks/outputs.tf for the v18+/v20 upgrade rationale. |
| <a name="output_cluster_name"></a> [cluster_name](#output_cluster_name)                                                                   | n/a                                                                                                                                                                                              |
| <a name="output_cluster_node_role"></a> [cluster_node_role](#output_cluster_node_role)                                                    | n/a                                                                                                                                                                                              |
| <a name="output_database_connection_string"></a> [database_connection_string](#output_database_connection_string)                         | n/a                                                                                                                                                                                              |
| <a name="output_database_instance_type"></a> [database_instance_type](#output_database_instance_type)                                     | n/a                                                                                                                                                                                              |
| <a name="output_database_password"></a> [database_password](#output_database_password)                                                    | n/a                                                                                                                                                                                              |
| <a name="output_database_username"></a> [database_username](#output_database_username)                                                    | n/a                                                                                                                                                                                              |
| <a name="output_eks_max_nodes_per_az"></a> [eks_max_nodes_per_az](#output_eks_max_nodes_per_az)                                           | n/a                                                                                                                                                                                              |
| <a name="output_eks_min_nodes_per_az"></a> [eks_min_nodes_per_az](#output_eks_min_nodes_per_az)                                           | n/a                                                                                                                                                                                              |
| <a name="output_eks_node_instance_type"></a> [eks_node_instance_type](#output_eks_node_instance_type)                                     | n/a                                                                                                                                                                                              |
| <a name="output_elasticache_connection_string"></a> [elasticache_connection_string](#output_elasticache_connection_string)                | n/a                                                                                                                                                                                              |
| <a name="output_kms_clickhouse_key_arn"></a> [kms_clickhouse_key_arn](#output_kms_clickhouse_key_arn)                                     | The Amazon Resource Name of the KMS key used to encrypt Weave data at rest in Clickhouse.                                                                                                        |
| <a name="output_kms_key_arn"></a> [kms_key_arn](#output_kms_key_arn)                                                                      | The Amazon Resource Name of the KMS key used to encrypt data at rest.                                                                                                                            |
| <a name="output_network_id"></a> [network_id](#output_network_id)                                                                         | The identity of the VPC in which resources are deployed.                                                                                                                                         |
| <a name="output_network_private_subnets"></a> [network_private_subnets](#output_network_private_subnets)                                  | The identities of the private subnetworks deployed within the VPC.                                                                                                                               |
| <a name="output_network_public_subnets"></a> [network_public_subnets](#output_network_public_subnets)                                     | The identities of the public subnetworks deployed within the VPC.                                                                                                                                |
| <a name="output_private_link_availability_zones"></a> [private_link_availability_zones](#output_private_link_availability_zones)          | The Availability Zones where the Private Link NLB endpoints are available                                                                                                                        |
| <a name="output_private_link_service_id"></a> [private_link_service_id](#output_private_link_service_id)                                  | The ID of the VPC Endpoint Service for Private Link                                                                                                                                              |
| <a name="output_private_link_service_name"></a> [private_link_service_name](#output_private_link_service_name)                            | The service name of the VPC Endpoint Service for Private Link                                                                                                                                    |
| <a name="output_redis_instance_type"></a> [redis_instance_type](#output_redis_instance_type)                                              | n/a                                                                                                                                                                                              |
| <a name="output_standardized_size"></a> [standardized_size](#output_standardized_size)                                                    | n/a                                                                                                                                                                                              |
| <a name="output_url"></a> [url](#output_url)                                                                                              | The URL to the W&B application                                                                                                                                                                   |
| <a name="output_wandb_spec"></a> [wandb_spec](#output_wandb_spec)                                                                         | n/a                                                                                                                                                                                              |

<!-- END_TF_DOCS -->

## Migrations

### Upgrading to Operator

See our upgrade guide [here](./docs/operator-migration/readme.md)

### Upgrading the EKS community module from v17 -> v20

The `terraform-aws-modules/eks/aws` pin moves from `~> 17.23` to `~> 20.37`
on this branch. v18 (and again v20) reorganized inputs, outputs, and
internal resource addresses, so a plain `terraform apply` against an
existing v17-managed cluster wants to destroy and recreate the EKS cluster,
node groups, IAM roles, and KMS key. To make this an in-place upgrade
instead — preserving the cluster control plane, its OIDC issuer, IAM
roles, security groups, and KMS key — this branch carries:

- Five name-preservation inputs on the `module "eks"` invocation in
  [`modules/app_eks/main.tf`](./modules/app_eks/main.tf) — `iam_role_name`,
  `iam_role_use_name_prefix`, `cluster_security_group_name`,
  `cluster_security_group_use_name_prefix`,
  `cluster_security_group_description`, plus `prefix_separator = ""` —
  to match v17-era resource names.
- Twelve `moved {}` blocks in
  [`modules/app_eks/moved.tf`](./modules/app_eks/moved.tf) and
  [`modules/app_eks/aws_auth_legacy.tf`](./modules/app_eks/aws_auth_legacy.tf)
  for the v17 -> v20 address renames.
- A `var.preserve_aws_auth_configmap` flag, when `true`, adopts the v17-era
  `kube-system/aws-auth` ConfigMap into wandb-side state for the
  authentication-mode cutover, then cleanly destroys it on a follow-up
  apply when set to `false`.

**Notes** The per-AZ `aws_launch_template` and `aws_eks_node_group` resources
_are_ replaced on the upgrade apply for two reasons:

1. **v20 naming change.** The community module hardcodes a `"-"` separator in
   `name_prefix` that v17 did not have, making the old name a `ForceNew` drift.
2. **AL2023 migration.** This module now mandates `ami_type =
"AL2023_x86_64_STANDARD"` on all node groups. Amazon Linux 2 reached
   end-of-life June 2025. `ami_type` is a `ForceNew` attribute on
   `aws_eks_node_group`, so **any cluster whose node groups were running AL2
   will have its node groups replaced when upgrading to this module version.**
   Clusters already on AL2023 see an in-place update only.

Both replacements are graceful: v20 sets `lifecycle.create_before_destroy =
true` on both resources, so new AL2023 nodes come up and go `Ready` before old
nodes drain and terminate. EC2 quota must accommodate briefly 2× steady-state
capacity per AZ during the apply window. See
[docs/upgrade-eks-20.md](docs/upgrade-eks-20.md) for the full impact table,
capacity pre-flight checklist, and rollback procedure.

Recommended upgrade sequence:

- Upgrade v17 → v20 on the current K8s version with `preserve_aws_auth_configmap = true`.
  Node groups are replaced in this apply (naming + AL2023, combined into one graceful CBD roll).
- Re-run with `preserve_aws_auth_configmap = false` after ~1 hour to retire the aws-auth ConfigMap.
- Proceed with individual EKS minor-version bumps one at a time: 1.30 → 1.31 → … → 1.34.

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

This upgrade is also intended to be used when upgrading eks to 1.30.

We have upgraded the following dependencies and Kubernetes addons:

- MySQL Aurora (8.0.mysql_aurora.3.07.1)
- redis (7.1)
- external-dns helm chart (v1.15.0)
- aws-efs-csi-driver (v2.0.7-eksbuild.1)
- aws-ebs-csi-driver (v1.35.0-eksbuild.1)
- coredns (v1.11.3-eksbuild.1)
- kube-proxy (v1.30.0-eksbuild.1)
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

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

### Terrafom version >= 1

### Credentials / Permissions

**AWS Services Used**

- AWS Identity & Access Management (IAM)
- AWS Key Management System (KMS)
- Amazon Aurora MySQL
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

<!-- BEGIN_TF_DOCS -->

## Requirements

| Name                                                                        | Version |
| --------------------------------------------------------------------------- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform)    | ~> 1.0  |
| <a name="requirement_aws"></a> [aws](#requirement_aws)                      | ~> 3.60 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement_kubernetes) | ~> 2.6  |

## Providers

| Name                                             | Version |
| ------------------------------------------------ | ------- |
| <a name="provider_aws"></a> [aws](#provider_aws) | 3.61.0  |

## Modules

| Name                                                                    | Source                        | Version |
| ----------------------------------------------------------------------- | ----------------------------- | ------- |
| <a name="module_acm"></a> [acm](#module_acm)                            | terraform-aws-modules/acm/aws | ~> 3.0  |
| <a name="module_app_eks"></a> [app_eks](#module_app_eks)                | ./modules/app_eks             | n/a     |
| <a name="module_app_kube"></a> [app_kube](#module_app_kube)             | ./modules/app_kube            | n/a     |
| <a name="module_app_lb"></a> [app_lb](#module_app_lb)                   | ./modules/app_lb              | n/a     |
| <a name="module_database"></a> [database](#module_database)             | ./modules/database            | n/a     |
| <a name="module_file_storage"></a> [file_storage](#module_file_storage) | ./modules/file_storage        | n/a     |
| <a name="module_kms"></a> [kms](#module_kms)                            | ./modules/kms                 | n/a     |
| <a name="module_networking"></a> [networking](#module_networking)       | ./modules/networking          | n/a     |

## Resources

| Name                                                                                                                                                    | Type        |
| ------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| [aws_autoscaling_attachment.autoscaling_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_attachment) | resource    |
| [aws_eks_cluster.app_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster)                               | data source |
| [aws_eks_cluster_auth.app_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth)                     | data source |

## Inputs

| Name                                                                                                         | Description                                                                                          | Type           | Default                                                  | Required |
| ------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------- | -------------- | -------------------------------------------------------- | :------: |
| <a name="input_acm_certificate_arn"></a> [acm_certificate_arn](#input_acm_certificate_arn)                   | The ARN of an existing ACM certificate.                                                              | `string`       | `null`                                                   |    no    |
| <a name="input_allowed_inbound_cidr"></a> [allowed_inbound_cidr](#input_allowed_inbound_cidr)                | (Optional) Allow HTTP(S) traffic to W&B. Defaults to all connections.                                | `list(string)` | <pre>[<br> "0.0.0.0/0"<br>]</pre>                        |    no    |
| <a name="input_allowed_inbound_ipv6_cidr"></a> [allowed_inbound_ipv6_cidr](#input_allowed_inbound_ipv6_cidr) | (Optional) Allow HTTP(S) traffic to W&B. Defaults to all connections.                                | `list(string)` | <pre>[<br> "::/0"<br>]</pre>                             |    no    |
| <a name="input_create_vpc"></a> [create_vpc](#input_create_vpc)                                              | (Optional) Boolean indicating whether to deploy a VPC (true) or not (false).                         | `bool`         | `true`                                                   |    no    |
| <a name="input_domain_name"></a> [domain_name](#input_domain_name)                                           | (Required) Domain for accessing the Weights & Biases UI.                                             | `string`       | n/a                                                      |   yes    |
| <a name="input_external_dns"></a> [external_dns](#input_external_dns)                                        | (Optional) Using external DNS. A `subdomain` must also be specified if this value is true.           | `bool`         | `false`                                                  |    no    |
| <a name="input_kms_key_alias"></a> [kms_key_alias](#input_kms_key_alias)                                     | KMS key alias for AWS KMS Customer managed key.                                                      | `string`       | `"wandb-managed-kms"`                                    |    no    |
| <a name="input_kms_key_deletion_window"></a> [kms_key_deletion_window](#input_kms_key_deletion_window)       | (Optional) Duration in days to destroy the key after it is deleted. Must be between 7 and 30 days.   | `number`       | `7`                                                      |    no    |
| <a name="input_kubernetes_public_access"></a> [kubernetes_public_access](#input_kubernetes_public_access)    | (Optional) Indicates whether or not the Amazon EKS public API server endpoint is enabled.            | `bool`         | `true`                                                   |    no    |
| <a name="input_namespace"></a> [namespace](#input_namespace)                                                 | String used for prefix resources.                                                                    | `string`       | n/a                                                      |   yes    |
| <a name="input_network_cidr"></a> [network_cidr](#input_network_cidr)                                        | (Optional) CIDR block for VPC.                                                                       | `string`       | `"10.0.0.0/16"`                                          |    no    |
| <a name="input_network_id"></a> [network_id](#input_network_id)                                              | The identity of the VPC in which resources will be deployed.                                         | `string`       | `""`                                                     |    no    |
| <a name="input_network_private_subnets"></a> [network_private_subnets](#input_network_private_subnets)       | (Optional) A list of public subnets inside the VPC.                                                  | `list(string)` | <pre>[<br> "10.0.32.0/20",<br> "10.0.48.0/20"<br>]</pre> |    no    |
| <a name="input_network_public_subnets"></a> [network_public_subnets](#input_network_public_subnets)          | (Optional) A list of private subnets inside the VPC.                                                 | `list(string)` | <pre>[<br> "10.0.0.0/20",<br> "10.0.16.0/20"<br>]</pre>  |    no    |
| <a name="input_public_access"></a> [public_access](#input_public_access)                                     | (Optional) Is this instance accessable a public domain.                                              | `bool`         | `false`                                                  |    no    |
| <a name="input_ssl_policy"></a> [ssl_policy](#input_ssl_policy)                                              | SSL policy to use on ALB listener                                                                    | `string`       | `"ELBSecurityPolicy-2016-08"`                            |    no    |
| <a name="input_subdomain"></a> [subdomain](#input_subdomain)                                                 | (Optional) Subdomain for accessing the Weights & Biases UI. Default creates record at Route53 Route. | `string`       | `null`                                                   |    no    |
| <a name="input_wandb_image"></a> [wandb_image](#input_wandb_image)                                           | Docker repository of to pull the wandb image from.                                                   | `string`       | `"wandb/local"`                                          |    no    |
| <a name="input_wandb_license"></a> [wandb_license](#input_wandb_license)                                     | The license for deploying Weights & Biases local.                                                    | `string`       | `null`                                                   |    no    |
| <a name="input_wandb_version"></a> [wandb_version](#input_wandb_version)                                     | The version of Weights & Biases local to deploy.                                                     | `string`       | `"latest"`                                               |    no    |
| <a name="input_zone_id"></a> [zone_id](#input_zone_id)                                                       | (Required) Domain for creating the Weights & Biases subdomain on.                                    | `string`       | n/a                                                      |   yes    |

## Outputs

| Name                                                                                                     | Description                                                           |
| -------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------- |
| <a name="output_database_port"></a> [database_port](#output_database_port)                               | n/a                                                                   |
| <a name="output_kms_key_arn"></a> [kms_key_arn](#output_kms_key_arn)                                     | The Amazon Resource Name of the KMS key used to encrypt data at rest. |
| <a name="output_network_id"></a> [network_id](#output_network_id)                                        | The identity of the VPC in which resources are deployed.              |
| <a name="output_network_private_subnets"></a> [network_private_subnets](#output_network_private_subnets) | The identities of the private subnetworks deployed within the VPC.    |
| <a name="output_network_public_subnets"></a> [network_public_subnets](#output_network_public_subnets)    | The identities of the public subnetworks deployed within the VPC.     |
| <a name="output_url"></a> [url](#output_url)                                                             | The URL to the W&B application                                        |

<!-- END_TF_DOCS -->

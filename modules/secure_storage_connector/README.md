# Weights & Biases Secure Storage Connector Module

This is a Terraform module for provisioning an s3 bucket to be used with Weights and Biases. 
A KMS key used to encrypt S3 objects will also be created by default. To use this bucket with Weights and Biases
multi-tenant cloud, pass `arn:aws:iam::725579432336:role/WandbIntegration` for the `aws_principal_arn` variable.

## AWS Services Used

- AWS Identity & Access Management (IAM)
- AWS Key Management System (KMS)
- Amazon S3

## How to Use This Module

- Ensure account meets module pre-requisites from above.
- Create a Terraform configuration that pulls in this module and specifies
  values of the required variables:

```hcl
provider "aws" {
  region = "<your AWS region>"
  default_tags {
    tags = "<your common tags>"
  }
}

module "secure_storage_connector" {
  source            = "wandb/wandb/aws//modules/secure_storage_connector"
  namespace         = "<prefix for naming AWS resources>"
  aws_principal_arn = "<aws principal that will access the bucket>"
}
```

- Run `terraform init` and `terraform apply`

<!-- BEGIN_TF_DOCS -->

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_file_storage"></a> [file\_storage](#module\_file\_storage) | ../../modules/file_storage | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_s3_bucket.file_storage](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_bucket) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_principal_arn"></a> [aws\_principal\_arn](#input\_aws\_principal\_arn) | AWS principal that can access the bucket | `string` | n/a | yes |
| <a name="input_create_kms_key"></a> [create\_kms\_key](#input\_create\_kms\_key) | If a KMS key should be created to encrypt S3 storage bucket objects. This can only be used when you set the value of sse\_algorithm as aws:kms. | `bool` | `true` | no |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | If the bucket should have deletion protection enabled. | `bool` | `false` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Prefix to use when creating resources | `string` | n/a | yes |
| <a name="input_sse_algorithm"></a> [sse\_algorithm](#input\_sse\_algorithm) | The server-side encryption algorithm to use. Valid values are `AES256` and `aws:kms` | `string` | `"aws:kms"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_bucket"></a> [bucket](#output\_bucket) | n/a |
| <a name="output_bucket_id"></a> [bucket\_id](#output\_bucket\_id) | n/a |
| <a name="output_bucket_kms_key"></a> [bucket\_kms\_key](#output\_bucket\_kms\_key) | n/a |

<!-- END_TF_DOCS -->
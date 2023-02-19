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

| Name                                                                        | Version |
| --------------------------------------------------------------------------- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform)    | ~> 1.0  |
| <a name="requirement_aws"></a> [aws](#requirement_aws)                      | ~> 3.60 |

## Providers

| Name                                             | Version |
| ------------------------------------------------ | ------- |
| <a name="provider_aws"></a> [aws](#provider_aws) | 3.61.0  |

## Inputs

| Name                                                                                       | Description                                                                                                                                    | Type     | Default   | Required |
|--------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------|----------|-----------|:--------:|
| <a name="input_namespace"></a> [namespace](#input_namespace)                               | Prefix to use when creating resources.                                                                                                         | `string` | `null`    |   yes    |
| <a name="input_create_kms_key"></a> [create_kms_key](#input_create_kms_key)                | If a KMS key should be created to encrypt S3 storage bucket objects. This can only be used when you set the value of sse_algorithm as aws:kms. | `bool`   | `true`    |    no    |
| <a name="input_deletion_protection"></a> [deletion_protection](#input_deletion_protection) | If the bucket should have deletion protection enabled.                                                                                         | `bool`   | `false`   |    no    |
| <a name="input_sse_algorithm"></a> [sse_algorithm](#input_sse_algorithm)                   | The server-side encryption algorithm to use. Valid values are `AES256` and `aws:kms`                                                           | `string` | `aws:kms` |    no    |
| <a name="input_aws_principal_arn"></a> [aws_principal_arn](#input_aws_principal_arn)       | AWS principal that can access the bucket                                                                                                       | `string` | `null`    |   yes    |

## Outputs

| Name                                                                        | Description                                                             |
|-----------------------------------------------------------------------------|-------------------------------------------------------------------------|
| <a name="bucket_name"></a> [bucket_name](#bucket_name)                      | The name of the bucket created                                          |
| <a name="bucket_arn"></a> [bucket_arn](#output_bucket_arn)                  | The arn of the bucket created                                           |
| <a name="bucket_kms_key_arn"></a> [bucket_kms_key_arn](#bucket_kms_key_arn) | The arn of the kms key created                                          |

<!-- END_TF_DOCS -->
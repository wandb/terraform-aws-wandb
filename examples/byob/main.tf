variable "bucket_prefix" {
  type        = string
  description = "Prefix of your bucket"
}

variable "region" {
  type        = string
  description = "AWS region the bucket will live in."
}

variable "deny_s3_access" {
  type        = bool
  description = "Conditonal to decide if S3 access needs to be restricted to a witelist. If true, additional_principal_arns must include the node role from W&B"
  default     = false
}

variable "additional_principal_arns" {
  type        = list(string)
  description = "List of ARN of the AWS principal to allow access to S3 and KMS. Must be filled out if deny_s3_access is true"
  default     = []
}

variable "s3_source_ip_address" {
  type        = list(string)
  description = "List of IP addresses to allow access to S3"
  default     = []
}

variable "s3_via_aws_service" {
  type        = bool
  description = "Boolean flag to allow S3 access only through AWS services"
  default     = false
}

variable "s3_source_vpce" {
  type        = list(string)
  description = "List of source VPC endpoints to allow access to S3"
  default     = []
}

variable "s3_source_orgs" {
  type        = list(string)
  description = "List of source AWS ORGS to allow access to S3"
  default     = []
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      GithubRepo = "terraform-aws-wandb"
      GithubOrg  = "wandb"
      Enviroment = "BringYourOwnBucket"
      Namespace  = "WeightsBiases"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  namespace = var.bucket_prefix

  # Weights & Biases Deployment Account
  wandb_deployment_account_id     = "830241207209"
  wandb_deployment_account_arn    = "arn:aws:iam::${local.wandb_deployment_account_id}:root"
  wandb_deployment_account_tf_arn = "arn:aws:iam::${local.wandb_deployment_account_id}:role/TerraformDeploy"

  current_account_root_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"

  combined_arns = concat(
    var.additional_principal_arns,
    [
      data.aws_caller_identity.current.arn,
      local.wandb_deployment_account_tf_arn,
      local.current_account_root_arn
    ]
  )

  secure_bucket = length(var.additional_principal_arns) > 0 && var.deny_s3_access
  final_arns    = local.secure_bucket ? distinct(local.combined_arns) : [local.wandb_deployment_account_arn]

  # Weights & Biases Deployment Org
  wandb_deployment_org_id = "o-hn017huuqa"

  combined_orgs = distinct(concat(var.s3_source_orgs, [local.wandb_deployment_org_id]))
}

resource "aws_kms_key" "key" {
  key_usage   = "ENCRYPT_DECRYPT"
  description = "Managed key to encrypt and decrypt storage file"
}

resource "aws_kms_key_policy" "key_policy" {
  key_id = aws_kms_key.key.key_id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Internal",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [
            "${data.aws_caller_identity.current.arn}",
            "${local.current_account_root_arn}"
          ]
        },
        "Action" : "kms:*",
        "Resource" : aws_kms_key.key.arn
      },
      {
        "Sid" : "External",
        "Effect" : "Allow",
        "Principal" : { "AWS" : local.final_arns },
        "Action" : [
          "kms:Decrypt",
          "kms:Describe*",
          "kms:Encrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*"
        ],
        "Resource" : aws_kms_key.key.arn
      }
    ]
  })
}

resource "aws_kms_alias" "key" {
  name          = "alias/${local.namespace}"
  target_key_id = aws_kms_key.key.key_id
}

module "resources" {
  source = "../../modules/file_storage"

  namespace     = local.namespace
  sse_algorithm = "aws:kms"
  kms_key_arn   = aws_kms_key.key.arn

  # Use redis queue
  create_queue = false

  deletion_protection = false
}

resource "aws_s3_bucket_policy" "default" {
  bucket = module.resources.bucket_name

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Id" : "WandBAccess",
    "Statement" : concat([
      # Give account permission to do whatever it wants to the bucket.
      {
        "Sid" : "WAndBAccountAccess",
        "Effect" : "Allow",
        "Principal" : { "AWS" : local.final_arns },
        "Action" : [
          "s3:GetObject*",
          "s3:GetEncryptionConfiguration",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:ListBucketVersions",
          "s3:AbortMultipartUpload",
          "s3:DeleteObject",
          "s3:PutObject",
          "s3:GetBucketCORS",
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning"
        ],
        "Resource" : [
          "${module.resources.bucket_arn}",
          "${module.resources.bucket_arn}/*",
        ]
      }],
      local.secure_bucket ? [
        {
          "Sid" : "S3-Deny-Policy-W&B",
          "Effect" : "Deny",
          "Principal" : "*",
          "Action" : "s3:*",
          "Resource" : [
            "${module.resources.bucket_arn}",
            "${module.resources.bucket_arn}/*",
          ],
          "Condition" : merge(
            length(var.additional_principal_arns) > 0 ? {
              "ArnNotLike" : {
                "aws:PrincipalArn" : local.final_arns
              }
            } : {},
            length(var.s3_source_ip_address) > 0 ? {
              "NotIpAddress" : {
                "aws:SourceIp" : var.s3_source_ip_address
              }
            } : {},
            var.s3_via_aws_service ? {
              "Bool" : {
                "aws:ViaAWSService" : true
              }
            } : {},
            length(var.s3_source_vpce) > 0 ? {
              "ForAllValues:StringNotEquals" : {
                "aws:sourceVpce" : var.s3_source_vpce
              }
            } : {},
            length(local.combined_orgs) > 0 ? {
              "StringNotEquals" : {
                "aws:PrincipalOrgID" : local.combined_orgs
              }
            } : {}
          )
      }] : []
    )
  })
}

output "bucket_name" {
  value = module.resources.bucket_name
}

output "bucket_kms_key_arn" {
  value = aws_kms_key.key.arn
}

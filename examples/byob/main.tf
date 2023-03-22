
variable "bucket_prefix" {
  type        = string
  description = "Prefix of your bucket"
}

variable "region" {
  type        = string
  description = "AWS region the bucket will live in."
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

locals {
  namespace = var.bucket_prefix

  # Weights & Biases Deployment Account
  wandb_deployment_account_id  = "830241207209"
  wandb_deployment_account_arn = "arn:aws:iam::${local.wandb_deployment_account_id}:root"
}

data "aws_caller_identity" "current" {}

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
        "Principal" : { "AWS" : "${data.aws_caller_identity.current.arn}" },
        "Action" : "kms:*",
        "Resource" : aws_kms_key.key.arn
      },
      {
        "Sid" : "External",
        "Effect" : "Allow",
        "Principal" : { "AWS" : "${local.wandb_deployment_node_role_account_arn}" },
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
    "Statement" : [
      # Give account permission to do whatever it wants to the bucket.
      {
        "Sid" : "WAndBAccountAccess",
        "Effect" : "Allow",
        "Principal" : { "AWS" : "${local.wandb_deployment_account_arn}" },
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
      },
    ]
  })
}

output "bucket_name" {
  value = module.resources.bucket_name
}

output "bucket_kms_key_arn" {
  value = aws_kms_key.key.arn
}

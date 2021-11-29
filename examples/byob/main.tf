provider "aws" {
  # region = "us-east-1"
  region = "us-west-2"

  default_tags {
    tags = {
      GithubRepo = "terraform-aws-wandb"
      GithubOrg  = "wandb"
      Enviroment = "Example"
      Example    = "BringYourOwnBucket"
    }
  }
}

locals {
  namespace = "wandb-kms-resources-2"

  # Weights & Biases Deployment Account
  wandb_deployment_account_id = "830241207209"
  wandb_deployment_account_arn = "arn:aws:iam::${local.wandb_deployment_account_id}:root"
}

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "key" {
  key_usage = "ENCRYPT_DECRYPT"
  description = "Managed key to encrypt and decrypt storage file"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Internal",
        "Effect" : "Allow",
        "Principal" : { "AWS" : "${data.aws_caller_identity.current.arn}" },
        "Action" : "kms:*",
        "Resource" : "*"
      },
      {
        "Sid" : "External",
        "Effect" : "Allow",
        "Principal" : { "AWS" : "${local.wandb_deployment_account_arn}" },
        "Action" : "kms:*",
        "Resource" : "*"
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

  # Use internal queue
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
        "Action" : "s3:*",
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
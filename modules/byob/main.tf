locals {
  namespace = var.bucket_prefix
  # Weights & Biases Deployment Account
  wandb_deployment_account_arn = "arn:aws:iam::${var.wandb_deployment_account_id}:root"
}

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "key" {
  count = var.kms_key_arn == null ? 1 : 0

  key_usage   = "ENCRYPT_DECRYPT"
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
        "Action" : [
          "kms:Decrypt",
          "kms:Describe*",
          "kms:Encrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
        ],
        "Resource" : "*"
      }
    ]
  })
}

locals {
  kms_key_id = var.kms_key_arn == null ? aws_kms_key.key.0.key_id : var.kms_key_arn.key_id
  kms_arn    = var.kms_key_arn == null ? aws_kms_key.key.0.arn : var.kms_key_arn.arn
}

resource "aws_kms_alias" "key" {
  name          = "alias/${local.namespace}"
  target_key_id = local.kms_key_id
}

module "resources" {
  source = "./file_storage"

  namespace     = local.namespace
  sse_algorithm = "aws:kms"
  kms_key_arn   = local.kms_arn

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
          "s3:PutObjectAcl",
        ],
        "Resource" : [
          "${module.resources.bucket_arn}",
          "${module.resources.bucket_arn}/*",
        ]
      },
    ]
  })
}

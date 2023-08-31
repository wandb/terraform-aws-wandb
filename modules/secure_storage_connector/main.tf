data "aws_caller_identity" "current" {}

resource "aws_kms_key" "key" {
  count       = var.create_kms_key ? 1 : 0
  key_usage   = "ENCRYPT_DECRYPT"
  description = "Wandb managed key to encrypt and decrypt file storage"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Internal",
        "Effect" : "Allow",
        "Principal" : { "AWS" : data.aws_caller_identity.current.arn },
        "Action" : "kms:*",
        "Resource" : "*"
      },
      {
        "Sid" : "External",
        "Effect" : "Allow",
        "Principal" : { "AWS" : var.aws_principal_arn },
        "Action" : [
          # minimum permissions needed for wandb access
          "kms:Decrypt",
          "kms:Describe*",
          "kms:Encrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*"
        ],
        Resource : "*"
      }
    ]
  })
}

module "file_storage" {
  source = "../../modules/file_storage"

  namespace     = var.namespace
  sse_algorithm = var.sse_algorithm
  kms_key_arn   = var.create_kms_key ? aws_kms_key.key[0].arn : null

  create_queue = false

  deletion_protection = var.deletion_protection
}

resource "aws_s3_bucket_policy" "s3_policy" {
  bucket = module.file_storage.bucket_name

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "WandbAccountAccess",
        "Effect" : "Allow",
        "Principal" : { "AWS" : var.aws_principal_arn },
        "Action" : [
          # minimum permissions needed for wandb access
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
          module.file_storage.bucket_arn,
          "${module.file_storage.bucket_arn}/*",
        ]
      }
    ]
  })
}

data "aws_s3_bucket" "file_storage" {
  bucket = module.file_storage.bucket_name
}

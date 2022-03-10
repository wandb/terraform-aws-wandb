data "aws_caller_identity" "current" {}

resource "aws_kms_key" "key" {
  deletion_window_in_days = var.key_deletion_window
  description             = "AWS KMS Customer-managed key to encrypt Weights & Biases resources"
  key_usage               = "ENCRYPT_DECRYPT"

  policy = var.key_policy != "" ? var.key_policy : jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Allow administration of the key",
        "Effect" : "Allow",
        "Principal" : { "AWS" : "${data.aws_caller_identity.current.arn}" },
        "Action" : "kms:*",
        "Resource" : "*"
      },
      {
        "Sid" : "Allow use of the key",
        "Effect" : "Allow",
        "Principal" : "*"
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        "Resource" : "*"
      },
    ]
  })

  tags = {
    Name = "wandb-kms-key"
  }
}

resource "aws_kms_alias" "key" {
  name          = "alias/${var.key_alias}"
  target_key_id = aws_kms_key.key.key_id
}

resource "aws_kms_grant" "main" {
  count = var.iam_principal_arn == "" ? 0 : 1

  grantee_principal = var.iam_principal_arn
  key_id            = aws_kms_key.key.key_id
  operations = [
    "Decrypt",
    "DescribeKey",
    "Encrypt",
    "GenerateDataKey",
    "GenerateDataKeyPair",
    "GenerateDataKeyPairWithoutPlaintext",
    "GenerateDataKeyPairWithoutPlaintext",
    "ReEncryptFrom",
    "ReEncryptTo",
  ]
}
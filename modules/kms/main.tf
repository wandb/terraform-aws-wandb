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
        "Sid" : "Allow use of the key and metadata to the account",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*",
          "kms:Get*",
          "kms:List*",
          "kms:RevokeGrant"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "Allow use for EBS to node groups",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
          ]
        },
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:Describe*"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : {
            "kms:CallerAccount" : "${data.aws_caller_identity.current.account_id}",
          },
          "StringLike" : {
            "kms:ViaService" : "ec2.*.amazonaws.com",
          }
        }
      }
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

resource "aws_kms_key" "clickhouse_key" {
  count = var.create_clickhouse_key ? 1 : 0

  deletion_window_in_days = var.key_deletion_window
  description             = "AWS KMS Customer-managed key to encrypt Weave resources in Clickhouse"
  key_usage               = "ENCRYPT_DECRYPT"

  policy = var.clickhouse_key_policy != "" ? var.clickhouse_key_policy : jsonencode({
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
        "Sid" : "Allow ClickHouse Access",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::576599896960:role/prod-kms-request-role"
        },
        "Action" : [
          "kms:GetPublicKey",
          "kms:Decrypt",
          "kms:GenerateDataKeyPair",
          "kms:Encrypt",
          "kms:GetKeyRotationStatus",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ],
        "Resource" : "*"
      },
    ]
  })

  tags = {
    Name = "wandb-kms-clickhouse-key"
  }
}



resource "aws_kms_alias" "clickhouse_key" {
  count = var.create_clickhouse_key ? 1 : 0

  name          = "alias/${var.clickhouse_key_alias}"
  target_key_id = aws_kms_key.clickhouse_key[0].key_id
}


resource "aws_kms_grant" "clickhouse" {
  count = var.create_clickhouse_key && (var.iam_principal_arn != "") ? 1 : 0

  grantee_principal = var.iam_principal_arn
  key_id            = aws_kms_key.clickhouse_key[0].key_id
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

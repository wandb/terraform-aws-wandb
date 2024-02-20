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
        "Sid" : "Temp SRE access for DR restore",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:sts::830241207209:assumed-role/AWSReservedSSO_SRE_f5adc5756fb1bc0f/george.scott@wandb.com"
  
        },
        "Action" : [
          "kms:*"
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

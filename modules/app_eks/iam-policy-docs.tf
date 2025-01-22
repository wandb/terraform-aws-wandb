data "aws_iam_policy_document" "node_cloudwatch" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    effect    = "Allow"
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    actions   = ["cloudwatch:PutMetricData"]
    effect    = "Allow"
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "node_IMDSv2" {
  statement {
    actions   = ["ec2:DescribeInstanceAttribute"]
    effect    = "Allow"
    resources = ["*"]
  }
}

locals {
  node_kms_actions = [
    "kms:Encrypt",
    "kms:Decrypt",
    "kms:ReEncrypt*",
    "kms:GenerateDataKey*",
    "kms:DescribeKey"
  ]
}
data "aws_iam_policy_document" "node_kms" {
  statement {
    actions   = local.node_kms_actions
    effect    = "Allow"
    resources = var.bucket_kms_key_arns
  }
  dynamic "statement" {
    for_each = var.map_bucket_permissions.mode == "open" ? [1] : []
    content {
      actions   = local.node_kms_actions
      effect    = "Allow"
      resources = ["*"]
      condition {
        test     = "StringNotEquals"
        variable = "kms:ResourceAccount"
        values   = [data.aws_caller_identity.current.account_id]
      }
    }
  }
  dynamic "statement" {
    for_each = var.map_bucket_permissions.mode == "lax" ? [1] : []
    content {
      actions   = local.node_kms_actions
      effect    = "Allow"
      resources = ["*"]
      condition {
        test     = "StringEquals"
        variable = "kms:ResourceAccount"
        values   = var.map_bucket_permissions.accounts
      }
    }
  }
}

data "aws_iam_policy_document" "node_sqs" {
  statement {
    actions   = ["sqs:*"]
    effect    = "Allow"
    resources = var.bucket_sqs_queue_arn == "" || var.bucket_sqs_queue_arn == null ? ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.node.name}"] : [var.bucket_sqs_queue_arn]
  }
}

data "aws_iam_policy_document" "node_s3" {
  statement {
    actions = ["s3:*"]
    effect  = "Allow"
    resources = [
      "${var.bucket_arn}",
      "${var.bucket_arn}/*"
    ]
  }
  dynamic "statement" {
    for_each = var.map_bucket_permissions.mode == "open" ? [1] : []
    content {
      actions   = ["s3:*"]
      effect    = "Allow"
      resources = ["*"]
      condition {
        test     = "StringNotEquals"
        variable = "s3:ResourceAccount"
        values   = [data.aws_caller_identity.current.account_id]
      }
    }
  }
  dynamic "statement" {
    for_each = var.map_bucket_permissions.mode == "lax" ? [1] : []
    content {
      actions   = ["s3:*"]
      effect    = "Allow"
      resources = ["*"]
      condition {
        test     = "StringEquals"
        variable = "s3:ResourceAccount"
        values   = var.map_bucket_permissions.accounts
      }
    }
  }
}

data "aws_iam_policy_document" "secrets_manager" {
  statement {
    actions = [
      "secretsmanager:CreateSecret",
      "secretsmanager:UpdateSecret",
      "secretsmanager:DeleteSecret",
      "secretsmanager:PutSecretValue",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DeleteSecretVersion"
    ]
    effect    = "Allow"
    resources = ["arn:aws:secretsmanager:*:${data.aws_caller_identity.current.account_id}:secret:${var.namespace}*"]
  }
}

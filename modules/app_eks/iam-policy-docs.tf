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

data "aws_iam_policy_document" "node_kms" {
  statement {
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    effect    = "Allow"
    resources = var.bucket_kms_key_arn == "" || var.bucket_kms_key_arn == null ? ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.node.name}"] : [var.bucket_kms_key_arn]
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
    effect  = "Allow"
    resources = ["arn:aws:secretsmanager:*:${data.aws_caller_identity.current.account_id}:secret:${var.namespace}*"]
  }
}

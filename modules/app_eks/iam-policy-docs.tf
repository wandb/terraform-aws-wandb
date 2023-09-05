data "aws_iam_policy_document" "node_cloudwatch" {
  statement {
    actions   = ["cloudwatch:PutMetricData"]
    effect    = "Allow"
    resources = ["*"]
  }

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

  //////////////////////////////////////////////////////
  // these permissions exist only so that the node can
  // delete previously created log streams specific
  // to the RDS and EKS modules. They should be 
  // commented out or removed after logging is uniformly
  // enabled, but may be required when performing upgrades
  // to the modules used herein.
  //////////////////////////////////////////////////////
  statement {
    actions = [
      "logs:DeleteLogGroup",
      "logs:DeleteLogStream"
    ]
    effect    = "Allow"
    resources = ["arn:aws:logs:*:*:*"]
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

resource "aws_iam_policy" "node_cloudwatch" {
  name   = "${var.namespace}-cloudwatch"
  policy = data.aws_iam_policy_document.node_cloudwatch.json
  lifecycle {
    create_before_destroy = false
  }
}

resource "aws_iam_policy" "node_IMDSv2" {
  name   = "${var.namespace}-IMDSv2"
  policy = data.aws_iam_policy_document.node_IMDSv2.json
  lifecycle {
    create_before_destroy = false
  }

}

resource "aws_iam_policy" "node_kms" {
  name   = "${var.namespace}-kms"
  policy = data.aws_iam_policy_document.node_kms.json
  lifecycle {
    create_before_destroy = false
  }
}

resource "aws_iam_policy" "node_sqs" {
  name   = "${var.namespace}-sqs"
  policy = data.aws_iam_policy_document.node_sqs.json
  lifecycle {
    create_before_destroy = false
  }
}

resource "aws_iam_policy" "node_s3" {
  name   = "${var.namespace}-s3"
  policy = data.aws_iam_policy_document.node_s3.json
  lifecycle {
    create_before_destroy = false
  }
}

resource "aws_iam_policy" "secrets_manager" {
  name   = "${var.namespace}-secrets-manager"
  policy = data.aws_iam_policy_document.secrets_manager.json
}

# IAM Policy for IRSA
resource "aws_iam_policy" "irsa" {
  name        = "${var.namespace}-irsa-policy"
  description = "IRSA IAM Policy"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*",
          "kms:*",
        ]
        Resource = "*"
      }
    ]
  })
}

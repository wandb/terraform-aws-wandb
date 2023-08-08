data "aws_iam_policy_document" "elasticache" {
  statement {
    sid     = "ff6"
    actions = ["s3:*"]
    effect  = "Allow"
    resources = [
      "${var.bucket_arn}",
      "${var.bucket_arn}/*"
    ]
  }
}


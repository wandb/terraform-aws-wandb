data "aws_iam_policy_document" "juicefs" {
  statement {
    actions = ["s3:*"]
    effect  = "Allow"
    resources = [
      "${data.aws_s3_bucket.juicefs.arn}",
      "${data.aws_s3_bucket.juicefs.arn}/*"
    ]
  }

  statement {
    actions = [
     "kms:Decrypt",
          "kms:Describe*",
          "kms:Encrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*"
    ]
    effect = "Allow"
    resources = [ "*" ]
  }
}


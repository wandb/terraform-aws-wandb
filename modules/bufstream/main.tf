resource "aws_s3_bucket" "bufstream" {
  bucket        = "${substr(var.namespace, 0, 20)}-bufstream"
  force_destroy = !var.deletion_protection

  tags = merge(var.tags, {
    role          = "bufstream-bucket"
    "customer-ns" = replace(var.namespace, "-cluster", "")
    cluster       = var.cluster_name
  })
}

resource "aws_s3_bucket_public_access_block" "bufstream" {
  bucket = aws_s3_bucket.bufstream.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_policy" "bufstream" {
  name        = "${substr(var.namespace, 0, 20)}-bufstream-s3"
  description = "Policy for Bufstream to access S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAllS3ActionsOnBufstreamBucket"
        Effect = "Allow"
        Action = ["s3:*"]
        Resource = [
          aws_s3_bucket.bufstream.arn,
          "${aws_s3_bucket.bufstream.arn}/*"
        ]
      }
    ]
  })

  tags = merge(var.tags, {
    role          = "bufstream-policy"
    "customer-ns" = replace(var.namespace, "-cluster", "")
    cluster       = var.cluster_name
  })
}

resource "aws_iam_role_policy_attachment" "bufstream" {
  role       = var.node_role_name
  policy_arn = aws_iam_policy.bufstream.arn
}

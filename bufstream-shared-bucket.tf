# Shared Bufstream bucket accessible from all namespaces in the EKS cluster
# Since all Kubernetes namespaces run on nodes that use the same node role,
# attaching the policy to the node role gives access from all namespaces

# AWS S3 bucket for shared bufstream access
resource "aws_s3_bucket" "bufstream_shared" {
  bucket        = "${var.namespace}-bufstream-sa-demo"
  force_destroy = false

  tags = {
    Namespace = var.namespace
    Role      = "bufstream-shared-bucket"
  }
}

# IAM Policy for S3 bucket access
resource "aws_iam_policy" "bufstream_shared" {
  name        = "${var.namespace}-bufstream-sa-demo-policy"
  description = "Policy for access to shared bufstream bucket from all namespaces"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAllS3ActionsOnSharedBufstreamBucket"
        Effect = "Allow"
        Action = [
          "s3:*"
        ]
        Resource = [
          aws_s3_bucket.bufstream_shared.arn,
          "${aws_s3_bucket.bufstream_shared.arn}/*"
        ]
      }
    ]
  })

  tags = {
    Namespace = var.namespace
  }
}

# Attach policy to the node role (used by all pods across all namespaces)
resource "aws_iam_role_policy_attachment" "bufstream_shared" {
  role       = module.app_eks.node_role.name
  policy_arn = aws_iam_policy.bufstream_shared.arn
}

# Outputs
output "bufstream_shared_bucket_name" {
  description = "Name of the shared bufstream S3 bucket"
  value       = aws_s3_bucket.bufstream_shared.bucket
}

output "bufstream_shared_bucket" {
  description = "Shared bufstream S3 bucket"
  value = {
    id         = aws_s3_bucket.bufstream_shared.id
    arn        = aws_s3_bucket.bufstream_shared.arn
    bucket     = aws_s3_bucket.bufstream_shared.bucket
    policy_arn = aws_iam_policy.bufstream_shared.arn
  }
}

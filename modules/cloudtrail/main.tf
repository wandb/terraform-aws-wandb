# S3 Bucket for CloudTrail logs
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket        = "${var.namespace}-${var.cloudtrail_bucket_name}"
  force_destroy = var.force_destroy

  tags = merge(var.tags, { Name = "CloudTrailLogs" })
}

# S3 Bucket Policy for CloudTrail
resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # Allow CloudTrail to write logs to the bucket
      {
        Sid    = "AllowCloudTrailWrite",
        Effect = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action   = "s3:PutObject",
        Resource = "arn:aws:s3:::${aws_s3_bucket.cloudtrail_logs.id}/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      # Allow CloudTrail to validate the bucket's ACL
      {
        Sid    = "AllowCloudTrailBucketACL",
        Effect = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action = [
          "s3:GetBucketAcl",
          "s3:PutBucketAcl"
        ],
        Resource = "arn:aws:s3:::${aws_s3_bucket.cloudtrail_logs.id}"
      },
      # Deny all HTTP (insecure) access
      {
        Sid       = "DenyInsecureConnections",
        Effect    = "Deny",
        Principal = "*",
        Action    = "s3:*",
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.cloudtrail_logs.id}",
          "arn:aws:s3:::${aws_s3_bucket.cloudtrail_logs.id}/*"
        ],
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# Lifecycle Rules for S3 Bucket
resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    id     = "TransitionToGlacier"
    status = "Enabled"

    filter {}

    transition {
      days          = var.log_lifecycle.transition_days
      storage_class = "GLACIER"
    }

    expiration {
      days = var.log_lifecycle.expiration_days
    }
  }
}

# CloudTrail Configuration
resource "aws_cloudtrail" "s3_event_logs" {
  name                          = "${var.namespace}-s3-events-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  include_global_service_events = var.include_global_service_events
  is_multi_region_trail         = var.multi_region_trail
  enable_log_file_validation    = var.enable_log_file_validation

  event_selector {
    read_write_type           = "All" # Log both read and write events
    include_management_events = true

    data_resource {
      type = "AWS::S3::Object"
      values = [
        "arn:aws:s3:::${aws_s3_bucket.cloudtrail_logs.id}/*"
      ]
    }
  }

  tags = merge(var.tags, { Name = "CloudTrail" })

  depends_on = [aws_s3_bucket_policy.cloudtrail_logs]
}

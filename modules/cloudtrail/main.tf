# S3 Bucket for CloudTrail logs
resource "aws_s3_bucket" "cloudtrail_logs" {
  count         = var.enable_cloudtrail_s3_logging ? 1 : 0
  bucket        = var.cloudtrail_bucket_name
  force_destroy = true

  tags = merge(var.tags, { Name = "CloudTrailLogs" })
}

# S3 Bucket Policy for CloudTrail
resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  count  = var.enable_cloudtrail_s3_logging ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowCloudTrailWrite",
        Effect = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action   = "s3:PutObject",
        Resource = "arn:aws:s3:::${aws_s3_bucket.cloudtrail_logs[0].id}/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid       = "DenyPublicAccess",
        Effect    = "Deny",
        Principal = "*",
        Action    = "s3:*",
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.cloudtrail_logs[0].id}",
          "arn:aws:s3:::${aws_s3_bucket.cloudtrail_logs[0].id}/*"
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
  count  = var.enable_cloudtrail_s3_logging ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail_logs[0].id

  rule {
    id     = "TransitionToGlacier"
    status = "Enabled"

    filter {
      prefix = ""
    }

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
  count                         = var.enable_cloudtrail_s3_logging ? 1 : 0
  name                          = "s3-events-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs[0].id
  include_global_service_events = var.include_global_service_events
  is_multi_region_trail         = var.multi_region_trail
  enable_log_file_validation    = var.enable_log_file_validation

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::*"]
    }
  }

  tags = merge(var.tags, { Name = "CloudTrail" })
}
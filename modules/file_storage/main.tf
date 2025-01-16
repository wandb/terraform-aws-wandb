resource "random_pet" "file_storage" {
  length = 2
}

resource "aws_sqs_queue" "file_storage" {
  count = var.create_queue ? 1 : 0
  name  = "${var.namespace}-file-storage-${random_pet.file_storage.id}"

  # Enable long-polling
  receive_wait_time_seconds = 10
  # kms_master_key_id = var.kms_key_arn
}

resource "aws_s3_bucket" "file_storage" {
  bucket = "${var.namespace}-file-storage-${random_pet.file_storage.id}"

  force_destroy = !var.deletion_protection

  # Configuration error if SQS does not exist
  # https://aws.amazon.com/premiumsupport/knowledge-center/unable-validate-destination-s3/
  depends_on = [aws_sqs_queue.file_storage]
}

# Apply an HTTPS-only bucket policy to each bucket
resource "aws_s3_bucket_policy" "https_only" {
  bucket = aws_s3_bucket.file_storage.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "DenyHTTPRequests",
        Effect    = "Deny",
        Principal = "*",
        Action    = "s3:*",
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.file_storage.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.file_storage.bucket}/*"
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

resource "aws_s3_bucket_acl" "file_storage" {
  depends_on = [aws_s3_bucket_ownership_controls.file_storage]

  bucket = aws_s3_bucket.file_storage.id
  acl    = "private"
}

resource "aws_s3_bucket_cors_configuration" "file_storage" {
  bucket = aws_s3_bucket.file_storage.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD", "PUT"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_ownership_controls" "file_storage" {
  bucket = aws_s3_bucket.file_storage.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "file_storage" {
  bucket                  = aws_s3_bucket.file_storage.id
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "file_storage" {
  bucket = aws_s3_bucket.file_storage.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = var.sse_algorithm
    }
  }
}

# Give the bucket permission to send messages onto the queue. Looks like we
# overide this value.
resource "aws_sqs_queue_policy" "file_storage" {
  count = var.create_queue && var.create_queue_policy ? 1 : 0

  queue_url = aws_sqs_queue.file_storage.0.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : ["sqs:SendMessage"],
        "Resource" : "arn:aws:sqs:*:*:${aws_sqs_queue.file_storage.0.name}",
        "Condition" : {
          "ArnEquals" : { "aws:SourceArn" : "${aws_s3_bucket.file_storage.arn}" }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_notification" "file_storage" {
  count = var.create_queue ? 1 : 0

  depends_on = [aws_sqs_queue_policy.file_storage]

  bucket = aws_s3_bucket.file_storage.id

  queue {
    queue_arn = aws_sqs_queue.file_storage.0.arn
    events    = ["s3:ObjectCreated:*"]
  }
}

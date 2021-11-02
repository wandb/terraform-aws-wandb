resource "aws_s3_bucket" "file_storage" {
  bucket = "${var.namespace}-wandb-files"
  acl    = "private"

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD", "PUT"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = var.kms_key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  force_destroy = true
}

resource "aws_sqs_queue" "file_storage" {
  name = "${var.namespace}-wandb-queue"

  # Enable long-polling
  receive_wait_time_seconds = 10

  kms_master_key_id = var.kms_key_arn

  # Permission to access the s3 bucket notification
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "arn:aws:sqs:*:*:s3-event-notification-queue",
      "Condition": {
        "ArnEquals": { "aws:SourceArn": "${aws_s3_bucket.file_storage.arn}" }
      }
    }
  ]
}
POLICY
}

resource "aws_s3_bucket_notification" "file_storage_notification" {
  bucket = aws_s3_bucket.file_storage.id

  queue {
    queue_arn = aws_sqs_queue.file_storage.arn
    events    = ["s3:ObjectCreated:*"]
  }
}
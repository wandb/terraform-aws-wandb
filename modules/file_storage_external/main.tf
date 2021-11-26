# Configures s3 policy
resource "aws_s3_bucket_policy" "default" {
  bucket = var.bucket_name

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Id" : "WandBAccountAccess",
    "Statement" : [
      # Give account permission to do whatever it wants to the bucket.
      {
        "Sid" : "1",
        "Effect" : "Allow",
        "Principal" : { "AWS" : "arn:aws:iam::${var.trusted_account_id}:root" },
        "Action" : "s3:*",
        "Resource" : [
          "${var.bucket_arn}",
          "${var.bucket_arn}/*",
        ]
      },
    ]
  })
}

# Configures sqs policy
resource "aws_sqs_queue_policy" "default" {
  queue_url = var.bucket_queue_name

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Id" : "WAndBAccess",
    "Statement" : [
      # Give account permission to do whatever it wants to the queue.
      {
        "Sid" : "WAndBAccountAccess",
        "Effect" : "Allow",
        "Principal" : { "AWS" : "arn:aws:iam::${var.trusted_account_id}:root" },
        "Action" : "sqs:*",
        "Resource" : "${var.bucket_queue_arn}",
      },
      # Give the bucket permission to send messages onto the queue. Looks like
      # we overide this value.
      {
        "Sid" : "BucketAccess",
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : ["sqs:SendMessage"],
        "Resource" : "arn:aws:sqs:*:*:${var.bucket_queue_name}",
        "Condition" : {
          "ArnEquals" : { "aws:SourceArn" : "${var.bucket_arn}" }
        }
      }
    ]
  })
}
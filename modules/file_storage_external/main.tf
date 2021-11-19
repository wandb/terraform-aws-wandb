data "aws_caller_identity" "current" {}

resource "aws_iam_role" "access" {
  name = "${var.namespace}-storage-access"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${var.trusted_account_id}:root"
        },
        "Action" : "sts:AssumeRole",
        "Condition" : {}
      }
    ]
  })

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "s3:*",
        "Resource" : [
          "${var.bucket_arn}",
          "${var.bucket_arn}/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : "sqs:*",
        "Resource" : [
          "${var.bucket_sqs_queue_arn}"
        ]
      }
    ]
  })
}
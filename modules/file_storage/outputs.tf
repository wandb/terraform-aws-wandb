output "bucket_name" {
  value = aws_s3_bucket.file_storage.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.file_storage.arn
}

output "bucket_region" {
  value = aws_s3_bucket.file_storage.region
}

output "bucket_queue_name" {
  value = aws_sqs_queue.file_storage.name
}

output "bucket_queue_arn" {
  value = aws_sqs_queue.file_storage.arn
}
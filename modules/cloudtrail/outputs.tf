output "cloudtrail_bucket_name" {
  description = "Name of the S3 bucket storing CloudTrail logs specific to S3 events"
  value       = aws_s3_bucket.cloudtrail_logs[0].bucket
  condition   = var.enable_cloudtrail_s3_logging
}

output "cloudtrail_bucket_arn" {
  description = "ARN of the S3 bucket storing CloudTrail logs specific to S3 events"
  value       = aws_s3_bucket.cloudtrail_logs[0].arn
  condition   = var.enable_cloudtrail_s3_logging
}

output "cloudtrail_name" {
  description = "Name of the CloudTrail instance"
  value       = aws_cloudtrail.example[0].name
  condition   = var.enable_cloudtrail_s3_logging
}

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail instance"
  value       = aws_cloudtrail.example[0].arn
  condition   = var.enable_cloudtrail_s3_logging
}
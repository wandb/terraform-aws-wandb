output "cloudtrail_bucket_name" {
  description = "Name of the S3 bucket storing CloudTrail logs specific to S3 events"
  value       = var.enable_cloudtrail_s3_logging ? aws_s3_bucket.cloudtrail_logs[0].bucket : null
}

output "cloudtrail_bucket_arn" {
  description = "ARN of the S3 bucket storing CloudTrail logs specific to S3 events"
  value       = var.enable_cloudtrail_s3_logging ? aws_s3_bucket.cloudtrail_logs[0].arn : null
}

output "cloudtrail_name" {
  description = "Name of the CloudTrail instance"
  value       = var.enable_cloudtrail_s3_logging ? aws_cloudtrail.s3_event_logs[0].name : null
}

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail instance"
  value       = var.enable_cloudtrail_s3_logging ? aws_cloudtrail.s3_event_logs[0].arn : null
}
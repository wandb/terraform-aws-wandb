output "s3_bucket_name" {
  description = "The name of the S3 bucket used for CloudTrail logs"
  value       = aws_s3_bucket.cloudtrail_logs.id
}

output "cloudtrail_name" {
  description = "The name of the CloudTrail"
  value       = aws_cloudtrail.single_trail.name
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket storing CloudTrail logs"
  value       = aws_s3_bucket.cloudtrail_logs.arn
}

output "s3_bucket_policy" {
  description = "The policy attached to the CloudTrail S3 bucket"
  value       = aws_s3_bucket_policy.cloudtrail_logs.id
}

output "namespace_folder" {
  description = "The namespace prefix created in the S3 bucket for this deployment"
  value       = "s3://${aws_s3_bucket.cloudtrail_logs.id}/${var.namespace}/"
}

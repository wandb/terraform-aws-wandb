output "s3_file_storage_name" {
  value       = aws_s3_bucket.file_storage.id
  description = "The name of the S3 bucket which contains files stoarged by Weights & Biases (e.g, artifacts)."
}

output "s3_file_storage_arn" {
  value       = aws_s3_bucket.file_storage.arn
  description = "The Amazon Resource Name of the S3 bucket which contains files stoarged by Weights & Biases (e.g, artifacts)."
}

output "s3_file_storage_bucket" {
  value       = aws_s3_bucket.file_storage.bucket
  description = "The bucket name of the S3 bucket which contains files stoarged by Weights & Biases (e.g, artifacts)."
}

output "s3_file_storage_region" {
  value       = aws_s3_bucket.file_storage.region
  description = "The region of the S3 bucket which contains files stoarged by Weights & Biases (e.g, artifacts)."
}
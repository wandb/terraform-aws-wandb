output "bucket" {
  description = "WandB S3 Bucketname"
  value = data.aws_s3_bucket.file_storage
}

output "bucket_id" {
  description = "WandB S3 bucket id"
  value = data.aws_s3_bucket.file_storage.id
}

output "bucket_kms_key" {
  description = "WandB S3 bucket kms key"
  value = var.create_kms_key ? aws_kms_key.key[0] : null
}

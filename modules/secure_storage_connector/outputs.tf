output "bucket" {
  value = data.aws_s3_bucket.file_storage
}

output "bucket_kms_key" {
  value = var.create_kms_key ? aws_kms_key.key[0] : null
}

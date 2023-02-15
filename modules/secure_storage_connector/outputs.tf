output "bucket_name" {
  value = module.file_storage.bucket_name
}

output "bucket_arn" {
  value = module.file_storage.bucket_arn
}

output "bucket_kms_key_arn" {
  value = var.create_kms_key ? aws_kms_key.key[0].arn : null
}
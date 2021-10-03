# KMS
output "kms_key_arn" {
  value       = aws_kms_key.key.arn
  description = "The Amazon Resource Name of the KMS key used to encrypt data at rest."
}


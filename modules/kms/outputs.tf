output "key" {
  value       = aws_kms_key.key
  description = "The KMS key used to encrypt data."
}
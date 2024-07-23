output "key" {
  value       = aws_kms_key.key
  description = "The KMS key used to encrypt Models data."
}


output "clickhouse_key" {
  value       = var.create_clickhouse_key ? aws_kms_key.clickhouse_key[0] : null
  description = "The KMS key used to encrypt Weave data in Clickhouse."
}

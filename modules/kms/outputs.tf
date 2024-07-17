output "key" {
  value       = aws_kms_key.key
  description = "The KMS key used to encrypt Models data."
}


output "clickhouse_key" {
  value       = aws_kms_key.clickhouse_key
  description = "The KMS key used to encrypt Weave data in Clickhouse."
}

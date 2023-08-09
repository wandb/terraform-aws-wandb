output "elasticache_arn" {
  description = "The ARN of the redis cluster"
  value       = aws_elasticache_replication_group.juicefs.arn
}

output "elasticache_password" {
  description = "The REDIS username used to access the JuiceFS metadatastore"
  value       = aws_elasticache_user.juicefs.passwords
  sensitive = false
}

output "elasticache_user" {
  description = "User used to access the JuiceF metadatastore"
  value       = aws_elasticache_user.juicefs.user_name
}

output "redis_url" {
  description = "URL of the Elasticache cluster"
  value       = aws_elasticache_replication_group.juicefs.configuration_endpoint_address
}

output "s3_access_key" {
  description = "Account access key used to access objectstore"
  value       = aws_iam_access_key.juicefs.id
}

output "s3_secret_key" {
  description = "Password used to access objectstore"
  value       = aws_iam_access_key.juicefs.encrypted_secret
  sensitive = false
}

output "s3_user" {
  description = "User used to access objectstore"
  value       = aws_iam_user.juicefs.name
}


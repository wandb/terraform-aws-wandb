output "elasticache_arn" {
  description = "The ARN of the redis cluster"
  value       = module.juicefs.elasticache_arn
}

output "elasticache_user" {
  description = "User used to access the JuiceF metadatastore"
  value       = module.juicefs.elasticache_user
}

output "metastore_url" {
  description = "The S3 URL used to back the Juice FS"
  value       = module.juicefs.metastore_url
}

output "objectstore_url" {
  description = "The S3 URL used to back the Juice FS"
  value       = module.juicefs.objectstore_url
}

output "redis_url" {
  description = "URL of the Elasticache cluster"
  value       = module.juicefs.redis_url
}

output "s3_access_key" {
  description = "Account access key used to access objectstore"
  value       = module.juicefs.s3_access_key
}

output "s3_user" {
  description = "User used to access objectstore"
  value       = module.juicefs.s3_user
}

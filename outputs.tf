# KMS
output "kms_key_arn" {
  value       = local.kms_key_arn
  description = "The Amazon Resource Name of the KMS key used to encrypt data at rest."
}

# Network
output "network_id" {
  value       = local.network_id
  description = "The identity of the VPC in which resources are deployed."
}

output "network_private_subnets" {
  value       = local.network_private_subnets
  description = "The identities of the private subnetworks deployed within the VPC."
}

output "network_public_subnets" {
  value       = local.network_public_subnets
  description = "The identities of the public subnetworks deployed within the VPC."
}

output "bucket_name" {
  value = local.bucket_name
}

output "bucket_region" {
  value = data.aws_s3_bucket.file_storage.region
}

output "bucket_queue_name" {
  value = local.bucket_queue_name
}

output "database_connection_string" {
  value = module.database.connection_string
}

output "cluster_id" {
  value = module.app_eks.cluster_id
}

output "cluster_node_role" {
  value = module.app_eks.node_role
}

output "url" {
  value       = local.url
  description = "The URL to the W&B application"
}

output "internal_app_port" {
  value = local.internal_app_port
}

output "elasticache_connection_string" {
  value = var.create_elasticache ? module.redis.0.connection_string : null
}

output "worker_node_security_group_id" {
  value = module.app_eks.worker_node_security_group_id
}

output "vpc_id" {
  value = module.networking.vpc_id
}

output "private_subnet_ids" {
  value = module.networking.private_subnets
}

output "elasticache_user" {
  value = module.juicefs.elasticache_user
}

output "elasticache_password" {
  value = module.juicefs.elasticache_password
}

output "elasticache_url" {
  value = module.juicefs.redis_url
}

output "s3_user" {
  value = module.juicefs.s3_user
}

output "s3_access_key" {
  value = module.juicefs.s3_access_key
}

output "s3_secret_key" {
  value = module.juicefs.s3_secret_key
}

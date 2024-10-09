output "bucket_name" {
  value = local.bucket_name
}
output "bucket_path" {
  value = var.bucket_path
}
output "bucket_queue_name" {
  value = local.bucket_queue_name
}
output "bucket_region" {
  value = data.aws_s3_bucket.file_storage.region
}

output "cluster_name" {
  value = module.app_eks.cluster_name
}

output "cluster_node_role" {
  value = module.app_eks.node_role
}
output "database_connection_string" {
  value = module.database.connection_string
}

output "database_username" {
  value = module.database.username
}

output "database_password" {
  sensitive = true
  value     = module.database.password
}

output "database_instance_type" {
  value = local.database_instance_class
}

output "elasticache_connection_string" {
  value = var.create_elasticache ? module.redis.0.connection_string : null
}

output "eks_min_node_count" {
  value = local.kubernetes_min_node_count
}

output "eks_max_node_count" {
  value = local.kubernetes_max_node_count
}

output "eks_node_instance_type" {
  value = local.kubernetes_instance_types
}

output "internal_app_port" {
  value = local.internal_app_port
}

output "kms_key_arn" {
  value       = local.default_kms_key
  description = "The Amazon Resource Name of the KMS key used to encrypt data at rest."
}

output "kms_clickhouse_key_arn" {
  value       = local.clickhouse_kms_key
  description = "The Amazon Resource Name of the KMS key used to encrypt Weave data at rest in Clickhouse."

}

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

output "redis_instance_type" {
  value = local.elasticache_node_type
}

output "standardized_size" {
  value = var.size
}

output "url" {
  value       = local.url
  description = "The URL to the W&B application"
}

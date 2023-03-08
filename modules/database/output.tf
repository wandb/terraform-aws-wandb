output "username" {
  value = var.master_username
}

output "password" {
  value = local.master_password
}

output "database_name" {
  value = var.database_name
}

output "endpoint" {
  description = "Writer endpoint for the cluster"
  value       = module.aurora.cluster_endpoint
}

output "reader_endpoint" {
  description = "A read-only endpoint for the cluster, automatically load-balanced across replicas"
  value       = module.aurora.cluster_reader_endpoint
}

output "connection_string" {
  value = "${var.master_username}:${local.master_password}@${module.aurora.cluster_endpoint}/${var.database_name}"
}

output "connection_string_reader" {
  value = "${var.master_username}:${local.master_password}@${module.aurora.cluster_reader_endpoint}/${var.database_name}"
}

output "security_group_id" {
  description = "The security group ID of the cluster"
  value       = module.aurora.security_group_id
}
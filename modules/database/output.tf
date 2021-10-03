output "rds_username" {
  value = local.master_username
}

output "rds_password" {
  value = local.master_password
}

output "rds_database" {
  value = local.database_name
}

output "rds_connection_string" {
  value = "${local.master_username}:${local.master_password}@${aws_rds_cluster.default.endpoint}/${local.database_name}"
}

output "rds_reader_connection_string" {
  value = "${local.master_username}:${local.master_password}@${aws_rds_cluster.default.reader_endpoint}/${local.database_name}"
}
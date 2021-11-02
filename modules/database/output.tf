output "username" {
  value = local.master_username
}

output "password" {
  value = local.master_password
}

output "database" {
  value = local.database_name
}

output "endpoint" {
  value = aws_rds_cluster.default.endpoint
}

output "connection_string" {
  value = "${local.master_username}:${local.master_password}@${aws_rds_cluster.default.endpoint}/${local.database_name}"
}

output "connection_string_reader" {
  value = "${local.master_username}:${local.master_password}@${aws_rds_cluster.default.reader_endpoint}/${local.database_name}"
}
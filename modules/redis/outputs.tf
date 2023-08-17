output "connection_string" {
  value = "${aws_elasticache_replication_group.default.primary_endpoint_address}:${aws_elasticache_replication_group.default.port}"
}

output "security_group_id" {
  value = aws_security_group.redis.id
}

output "subnet_group_name" {
  value = aws_elasticache_replication_group.default.subnet_group_name
}


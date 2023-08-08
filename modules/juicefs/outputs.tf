output "arn" {
  description = "The ARN of the redis cluster"
  value       = aws_elasticache_cluster.arn
}

output "cache_nodes" {
  description = "A list of all of the cache nodes"
  value       = aws_elasticache_cluster.cache_nodes
}

output "engine_version" {
  description = "The ARN of the redis cluster"
  value       = aws_elasticache_cluster.engine_version_actual
}

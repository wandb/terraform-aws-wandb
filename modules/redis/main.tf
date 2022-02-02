locals {
  redis_version = "4.0.10"
}

resource "aws_elasticache_replication_group" "default" {
  replication_group_id          = "${var.namespace}-rep-group"
  replication_group_description = "${var.namespace}-rep-group"
  node_type                     = "cache.m4.large"
  number_cache_clusters         = 2
  parameter_group_name          = "default.redis4.0"
  automatic_failover_enabled    = true
  multi_az_enabled              = true
  port                          = 6379
  maintenance_window            = var.preferred_maintenance_window
  engine_version                = local.redis_version
}
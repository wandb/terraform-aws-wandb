resource "aws_elasticache_replication_group" "juicefs" {
  apply_immediately                = true
  at_rest_encryption_enabled       = true
  auto_minor_version_upgrade       = true
  automatic_failover_enabled       = true
  engine                           = "redis"
  engine_version                   = "7.2"
  maintenance_window               = "sun:05:00-sun:09:00"
  multi_az_enabled                 = false
  node_type                        = "cache.m7g.xlarge"
  num_cache_clusters               = 1
  parameter_group_name             = aws_elasticache_parameter_group.juicefs.name
  port                             = 6379
  replication_group_description        = "${var.namespace}-juicefs-metadatastore" 
  replication_group_id             = "${var.namespace}-juicefs-metadatastore"
  replicas_per_node_group          = 1
  security_group_ids               = var.security_group_ids
  snapshot_retention_limit = 7
  subnet_group_name                = "${var.namespace}-juicefs-metadatastore"
  transit_encryption_enabled       = true
}

resource "aws_elasticache_parameter_group" "juicefs" {
  name   = "${var.namespace}-juicefs"
  family = "default.redis7.cluster.on"

  parameter {
    name  = "activedefrag"
    value = "yes"
  }

  parameter {
    name  = "appendfsync"
    value = "no"
  }

  parameter {
    name  = "appendonly"
    value = "yes"
  }

  parameter {
    name  = "databases"
    value = 4
  }

  parameter {
    name  = "latency-tracking"
    value = "yes"
  }

  parameter {
    name  = "maxmemory-policy"
    value = "noeviction"
  }
}
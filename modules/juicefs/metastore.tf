resource "aws_elasticache_cluster" "juicefs" {
  apply_immediately                = true
  auto_minor_version_upgrade       = true
  cluster_id                       = "${var.namespace}-juicefs-metadatastore"
  engine                           = "redis"
  engine_version                   = "7.2"
  maintenance_window               = "sun:05:00-sun:09:00"
  node_type                        = "cache.m7g.xlarge"
  parameter_group_name             = "default.redis7"
  port                             = 6379
  snapshotsnapshot_retention_limit = 7
  subnet_group_name = aws_elasticache_subnet_group.juicefs.name
}

resource "aws_elasticache_subnet_group" "juicefs" {
  name       =  "${var.namespace}-juicefs"
  subnet_ids = var.subnet_ids
}
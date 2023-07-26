resource "aws_elasticache_replication_group" "default" {
  at_rest_encryption_enabled = true
  automatic_failover_enabled = true
  description                = "${var.namespace}-rep-group"
  engine_version             = "6.x"
  kms_key_id                 = var.kms_key_arn
  maintenance_window         = var.preferred_maintenance_window
  multi_az_enabled           = true
  node_type                  = var.node_type
  num_cache_clusters         = 2
  parameter_group_name       = "default.redis6.x"
  port                       = 6379
  replication_group_id       = "${var.namespace}-rep-group"
  security_group_ids         = [aws_security_group.redis.id]
  snapshot_retention_limit   = 1
  subnet_group_name          = var.redis_subnet_group_name
  transit_encryption_enabled = true
}

resource "aws_security_group" "redis" {
  name   = "${var.namespace}-elasticache-security-group"
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "ingress" {
  cidr_blocks       = var.vpc_subnets_cidr_blocks
  from_port         = "6379"
  protocol          = "tcp"
  security_group_id = aws_security_group.redis.id
  to_port           = "6379"
  type              = "ingress"
}

resource "aws_security_group_rule" "egress" {
  cidr_blocks       = var.vpc_subnets_cidr_blocks
  from_port         = "6379"
  protocol          = "tcp"
  security_group_id = aws_security_group.redis.id
  to_port           = "6379"
  type              = "egress"
}
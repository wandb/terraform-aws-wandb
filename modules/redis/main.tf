locals {
  redis_version = "6.x"
}

resource "aws_elasticache_replication_group" "default" {
  replication_group_id          = "${var.namespace}-rep-group"
  replication_group_description = "${var.namespace}-rep-group"
  number_cache_clusters         = 2
  port                          = 6379

  node_type            = "cache.t2.medium"
  parameter_group_name = "default.redis6.x"
  engine_version       = local.redis_version

  automatic_failover_enabled = true
  multi_az_enabled           = true
  maintenance_window         = var.preferred_maintenance_window

  subnet_group_name  = var.redis_subnet_group_name
  security_group_ids = [aws_security_group.redis.id]

  kms_key_id                 = var.kms_key_arn
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
}

resource "aws_security_group" "redis" {
  name   = "${var.namespace}-elasticache-security-group"
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "ingress" {
  type              = "ingress"
  protocol          = "tcp"
  from_port         = "6379"
  to_port           = "6379"
  cidr_blocks       = var.vpc_subnets_cidr_blocks
  security_group_id = aws_security_group.redis.id
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  protocol          = "tcp"
  from_port         = "6379"
  to_port           = "6379"
  cidr_blocks       = var.vpc_subnets_cidr_blocks
  security_group_id = aws_security_group.redis.id
}
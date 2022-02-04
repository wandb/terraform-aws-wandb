locals {
  redis_version = "6.x"
}

resource "aws_elasticache_replication_group" "default" {
  replication_group_id          = "${var.namespace}-rep-group"
  replication_group_description = "${var.namespace}-rep-group"
  number_cache_clusters         = 2
  port                          = 6379

  node_type                     = "cache.t2.medium"
  parameter_group_name          = "default.redis6.x"
  engine_version                = local.redis_version

  automatic_failover_enabled    = true
  multi_az_enabled              = true
  maintenance_window            = var.preferred_maintenance_window

  subnet_group_name             = var.redis_subnet_group_name
  security_group_ids            = [aws_security_group.redis.id]
}

resource "aws_security_group" "redis" {
  name   = "${var.namespace}-elasticache-security-group"
  vpc_id = var.vpc_id

  ingress {
    protocol         = "tcp"
    from_port        = "6379"
    to_port          =  "6379"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
locals {
  database_name   = "wandb_local"
  master_username = "wandb"
  master_password = random_string.master_password.result

  major_mysql_version  = "5.7"
  aurora_mysql_version = "2.10.0"
}

# Random string to use as initial master password
resource "random_string" "master_password" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "default" {
  name = "${var.namespace}-aurora-db-57-secret"

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

resource "aws_secretsmanager_secret_version" "default" {
  secret_id     = aws_secretsmanager_secret.default.id
  secret_string = random_string.master_password.result
}

resource "aws_db_parameter_group" "default" {
  name        = "${var.namespace}-aurora-db-57-parameter-group"
  family      = "aurora-mysql5.7"
  description = "${var.namespace}-aurora-db-57-parameter-group"

  parameter {
    name         = "performance_schema"
    value        = "1"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "slow_query_log"
    value        = "1"
    apply_method = "pending-reboot"
  }

  parameter {
    name  = "long_query_time"
    value = "4"
  }

  parameter {
    name         = "max_prepared_stmt_count"
    value        = "1048576"
    apply_method = "pending-reboot"
  }

  parameter {
    name  = "max_execution_time"
    value = "60000"
  }
}

resource "aws_rds_cluster_parameter_group" "default" {
  name        = "${var.namespace}-aurora-57-cluster-parameter-group"
  family      = "aurora-mysql5.7"
  description = "${var.namespace}-aurora-57-cluster-parameter-group"

  parameter {
    name         = "binlog_format"
    value        = "ROW"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "innodb_online_alter_log_max_size"
    value        = "268435456"
    apply_method = "pending-reboot"
  }
}



module "aurora" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "6.1.3"

  name           = var.namespace
  engine         = "aurora-mysql"
  engine_version = "5.7"

  instance_class = var.instance_class
  instances      = { 1 = {} }

  autoscaling_enabled      = true
  autoscaling_min_capacity = 1
  autoscaling_max_capacity = 3

  deletion_protection = var.deletion_protection

  vpc_id                 = var.vpc_id
  db_subnet_group_name   = var.db_subnet_group_name
  create_db_subnet_group = var.create_db_subnet_group
  subnets                = var.subnets

  database_name = local.database_name

  create_security_group = true
  allowed_cidr_blocks   = var.allowed_cidr_blocks

  iam_database_authentication_enabled = false
  master_username                     = local.master_username
  master_password                     = aws_secretsmanager_secret_version.default.secret_string
  create_random_password              = false

  storage_encrypted = true
  kms_key_id        = var.kms_key_arn

  apply_immediately   = true
  skip_final_snapshot = true

  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = var.preferred_backup_window
  preferred_maintenance_window = var.preferred_maintenance_window

  db_parameter_group_name         = aws_db_parameter_group.default.id
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.default.id
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
}

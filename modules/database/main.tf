locals {
  database_name   = "wandb_local"
  master_username = "wandb"
  master_password = random_string.master_password.result
}

# Random string to use as initial master password
resource "random_string" "master_password" {
  length  = 32
  special = false
}

locals {
  is_mysql_80            = var.engine_version == "8.0.mysql_aurora.3.01.0"
  engine_version_tag     = local.is_mysql_80 ? "80" : "57"
  parameter_family       = local.is_mysql_80 ? "aurora-mysql8.0" : "aurora-mysql5.7"
  parameter_group_name   = "${var.namespace}-aurora-db-${local.engine_version_tag}-parameter-group"
  parameter_cluster_name = "${var.namespace}-aurora-${local.engine_version_tag}-cluster-parameter-group"
}

resource "aws_db_parameter_group" "default" {
  name        = local.parameter_group_name
  family      = local.parameter_family
  description = "Weights & Biases database parameter group for MySQL ${var.engine_version}"

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

  parameter {
    name  = "sort_buffer_size"
    value = var.sort_buffer_size
  }

  lifecycle {
    ignore_changes = [description]
  }
}

resource "aws_rds_cluster_parameter_group" "default" {
  name        = local.parameter_cluster_name
  family      = local.parameter_family
  description = "Weights & Biases cluster parameter group for MySQL ${var.engine_version}"

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

  lifecycle {
    ignore_changes = [description]
  }
}

module "aurora" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "6.2.0"

  name           = var.namespace
  engine         = "aurora-mysql"
  engine_version = var.engine_version

  allow_major_version_upgrade = true

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

  snapshot_identifier = var.snapshot_identifier

  database_name = local.database_name

  create_security_group = true
  allowed_cidr_blocks   = var.allowed_cidr_blocks

  iam_database_authentication_enabled = false
  master_username                     = local.master_username
  master_password                     = local.master_password
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

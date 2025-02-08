locals {
  master_password = random_string.master_password.result
}

# Random string to use as initial master password
resource "random_string" "master_password" {
  length  = 32
  special = false
}

locals {
  engine_version_tag     = "80"
  parameter_family       = "aurora-mysql8.0"
  parameter_group_name   = "${var.namespace}-aurora-db-${local.engine_version_tag}-parameter-group"
  parameter_cluster_name = "${var.namespace}-aurora-${local.engine_version_tag}-cluster-parameter-group"
}

#https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraMySQL.Reference.ParameterGroups.html#AuroraMySQL.Reference.Parameters.Instance
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

  parameter {
    name  = "innodb_lru_scan_depth"
    value = var.innodb_lru_scan_depth
  }

  lifecycle {
    ignore_changes = [description]
  }
}

# https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraMySQL.Reference.ParameterGroups.html#AuroraMySQL.Reference.Parameters.Cluster
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

  parameter {
    name         = "binlog_row_image"
    value        = var.binlog_row_image
    apply_method = "pending-reboot"
  }

  lifecycle {
    ignore_changes = [description]
  }
}

module "aurora" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "7.7.1"

  allow_major_version_upgrade         = true
  allowed_cidr_blocks                 = var.allowed_cidr_blocks
  apply_immediately                   = true
  autoscaling_enabled                 = false
  backup_retention_period             = var.backup_retention_period
  create_db_subnet_group              = var.create_db_subnet_group
  create_random_password              = false
  create_security_group               = true
  database_name                       = var.database_name
  db_cluster_parameter_group_name     = aws_rds_cluster_parameter_group.default.id
  db_parameter_group_name             = aws_db_parameter_group.default.id
  db_subnet_group_name                = var.db_subnet_group_name
  deletion_protection                 = var.deletion_protection
  enabled_cloudwatch_logs_exports     = ["audit", "error", "general", "slowquery"]
  engine                              = "aurora-mysql"
  engine_version                      = var.engine_version
  iam_database_authentication_enabled = false
  iam_role_force_detach_policies      = true
  iam_role_name                       = "${var.namespace}-aurora-monitoring"
  instance_class                      = var.instance_class
  instances                           = { 1 = {} }
  kms_key_id                          = var.kms_key_arn
  master_password                     = local.master_password
  master_username                     = var.master_username
  monitoring_interval                 = 15
  name                                = var.namespace
  ////////////////////////////////////////////////////////////////////////////////////////
  // !!! note on performance insights !!!
  // AWS offers 7 days of performance insights free. keeping them after this period
  // incurs a per-vcpu cost. so we can keep them for 7 days and they're free
  ////////////////////////////////////////////////////////////////////////////////////////
  performance_insights_enabled          = true
  performance_insights_kms_key_id       = (var.performance_insights_kms_key_arn == "" || var.performance_insights_kms_key_arn == null) ? var.kms_key_arn : var.performance_insights_kms_key_arn
  performance_insights_retention_period = 7
  preferred_backup_window               = var.preferred_backup_window
  preferred_maintenance_window          = var.preferred_maintenance_window
  security_group_tags                   = { "Namespace" : var.namespace }
  skip_final_snapshot                   = true
  snapshot_identifier                   = var.snapshot_identifier
  storage_encrypted                     = true
  subnets                               = var.subnets
  vpc_id                                = var.vpc_id


}

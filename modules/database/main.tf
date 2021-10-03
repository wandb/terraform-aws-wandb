locals {
  database_name   = "wandb_local"
  master_username = "wandb"
  master_password = random_string.master_password.result

  major_mysql_version  = "5.7"
  aurora_mysql_version = "2.10.0"
}

# Random string to use as master password
resource "random_string" "master_password" {
  length  = 20
  special = false
}

resource "aws_db_subnet_group" "default" {
  name       = "${var.namespace}-db-subnets"
  subnet_ids = var.network_private_subnets
}

resource "aws_rds_cluster" "default" {
  cluster_identifier   = "${var.namespace}-db"
  db_subnet_group_name = aws_db_subnet_group.default.name

  engine         = "aurora-mysql"
  engine_version = "${local.major_mysql_version}.mysql_aurora.${local.aurora_mysql_version}"

  preferred_backup_window      = var.db_backup_window
  preferred_maintenance_window = var.db_maintenance_window
  backup_retention_period      = var.db_backup_retention
  apply_immediately            = var.apply_immediately

  database_name   = local.database_name
  master_username = local.master_username
  master_password = local.master_password

  iam_database_authentication_enabled = var.db_iam_database_authentication_enabled

  storage_encrypted = var.db_storage_encrypted
  kms_key_id        = var.kms_key_arn
}

resource "aws_rds_cluster_instance" "default" {
  count = var.db_replica_count

  identifier           = "${var.namespace}-db-instance-${count.index}"
  engine               = "aurora-mysql"
  cluster_identifier   = aws_rds_cluster.default.id
  instance_class       = var.db_size
  apply_immediately    = var.apply_immediately
  db_subnet_group_name = aws_db_subnet_group.default.name
}
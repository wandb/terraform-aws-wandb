variable "allowed_cidr_blocks" {
  description = "A list of CIDR blocks which are allowed to access the database"
  nullable    = false
  type        = list(string)
}

variable "backup_retention_period" {
  default     = 30
  description = "The days to retain backups for."
  nullable    = false
  type        = number
}

variable "binlog_row_image" {
  default     = "minimal"
  description = "Value for binlog_row_image"
  nullable    = false
  type        = string
}

variable "create_db_subnet_group" {
  default     = true
  description = "Determines whether to create the databae subnet group or use existing"
  nullable    = false
  type        = string
}

variable "db_subnet_group_name" {
  default     = ""
  description = "The name of the subnet group name (existing or created)"
  nullable    = true
  type        = string
}

variable "deletion_protection" {
  default     = true
  description = "If the DB instance should have deletion protection enabled. The database can't be deleted when this value is set to `true`."
  nullable    = false
  type        = bool
}

variable "engine_version" {
  description = "Version for MySQL Auora to use"
  nullable    = false
  type        = string
}

variable "iam_database_authentication_enabled" {
  description = "Specifies whether or mappings of AWS Identity and Access Management (IAM) accounts to database accounts is enabled"
  type        = bool
  nullable    = false
}

variable "instance_class" {
  description = "Instance type to use at master instance."
  nullable    = false
  type        = string
}

variable "kms_key_arn" {
  description = "The ARN for the KMS encryption key."
  nullable    = false
  type        = string
}

variable "namespace" {
  type        = string
  description = "The name prefix for all resources created."
}

variable "performance_insights_kms_key_arn" {
  description = "Specifies an existing KMS key ARN to encrypt the performance insights data if performance_insights_enabled is was enabled out of band"
  nullable    = true
  type        = string
}

variable "preferred_backup_window" {
  description = "The daily time range during which automated backups are created if automated backups are enabled using the `backup_retention_period` parameter. Time in UTC"
  type        = string
  default     = "02:00-03:00"
}

variable "preferred_maintenance_window" {
  description = "The weekly time range during which system maintenance can occur, in (UTC)"
  type        = string
  default     = "sun:05:00-sun:06:00"
}

variable "subnets" {
  default     = []
  description = "List of subnet IDs used by database subnet group created."
  nullable    = false
  type        = list(string)
}


variable "vpc_id" {
  description = "The identity of the VPC in which the security group attached to the MySQL Aurora instances will be deployed."
  nullable    = false
  type        = string
}














variable "snapshot_identifier" {
  description = "Specifies whether or not to create this cluster from a snapshot. You can use either the name or ARN when specifying a DB cluster snapshot, or the ARN when specifying a DB snapshot"
  type        = string
  default     = null
}

variable "sort_buffer_size" {
  description = "Specifies the sort_buffer_size value to set for the database"
  type        = number
  default     = 262144
}

variable "database_name" {
  description = "Specifies the name of the database"
  type        = string
  default     = "wandb_local"
}

variable "master_username" {
  description = "Specifies the master_username value to set for the database"
  type        = string
  default     = "wandb"
}

# DB Instance Parameters
variable "innodb_lru_scan_depth" {
  description = "Specifies the innodb_lru_scan_depth value to set for the database"
  type        = number
  default     = 128
}


# Cluster parametes

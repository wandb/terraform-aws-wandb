variable "kms_key_arn" {
  description = "The ARN for the KMS encryption key."
  type        = string
}

variable "namespace" {
  type        = string
  description = "The name prefix for all resources created."
}

variable "vpc_id" {
  description = "The identity of the VPC in which the security group attached to the MySQL Aurora instances will be deployed."
  type        = string
}

variable "engine_version" {
  description = "Version for MySQL Auora to use"
  type        = string
  default     = "5.7"

  validation {
    condition     = contains(["5.7", "8.0.mysql_aurora.3.01.0"], var.engine_version)
    error_message = "We only support MySQL: \"5.7\"; \"8.0.mysql_aurora.3.01.0\""
  }
}

variable "create_db_subnet_group" {
  description = "Determines whether to create the databae subnet group or use existing"
  type        = string
  default     = true
}

variable "db_subnet_group_name" {
  description = "The name of the subnet group name (existing or created)"
  type        = string
  default     = ""
}

variable "subnets" {
  description = "List of subnet IDs used by database subnet group created."
  type        = list(string)
  default     = []
}

variable "instance_class" {
  description = "Instance type to use at master instance."
  type        = string
  default     = "db.r5.large"
}

variable "deletion_protection" {
  description = "If the DB instance should have deletion protection enabled. The database can't be deleted when this value is set to `true`."
  type        = bool
  default     = true
}

variable "backup_retention_period" {
  description = "The days to retain backups for."
  type        = number
  default     = 30
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
variable "iam_database_authentication_enabled" {
  description = "Specifies whether or mappings of AWS Identity and Access Management (IAM) accounts to database accounts is enabled"
  type        = bool
  default     = true
}

variable "allowed_cidr_blocks" {
  description = "A list of CIDR blocks which are allowed to access the database"
  type        = list(string)
  default     = []
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

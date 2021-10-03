variable "kms_key_arn" {
  description = "(Optional) The ARN for the KMS encryption key if one is set to the cluster."
  type        = string
  default     = ""
}

variable "namespace" {
  type        = string
  description = "(Required) The name prefix for all resources created."
}

variable "network_id" {
  description = "(Required) The identity of the VPC in which the security group attached to the MySQL Aurora instances will be deployed."
  type        = string
}

variable "network_private_subnets" {
  description = "(Required) A list of the identities of the private subnetworks in which the MySQL Aurora instances will be deployed."
  type        = list(string)
}

variable "db_size" {
  type        = string
  default     = "db.r5.large"
  description = "(Optional) Aurora RDS instance size."
}

variable "db_backup_retention" {
  type        = number
  description = "(Optional) The days to retain backups for. Must be between 0 and 35"
  default     = 14
}

variable "db_backup_window" {
  type        = string
  description = "(Optional) The daily time range (in UTC) during which automated backups are created if they are enabled"
  default     = null
}
variable "db_maintenance_window" {
  type        = string
  description = "(Optional) The daily time range (in UTC) during which automated backups are created if they are enabled"
  default     = null
}

variable "db_replica_count" {
  description = "(Optional) Number of reader nodes to create."
  type        = number
  default     = 1
}

variable "db_storage_encrypted" {
  description = "(Optional) Specifies whether the underlying storage layer should be encrypted"
  type        = bool
  default     = true
}

variable "db_iam_database_authentication_enabled" {
  description = "(Optional) Specifies whether IAM Database authentication should be enabled or not. Not all versions and instances are supported. Refer to the AWS documentation to see which versions are supported"
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Determines whether or not any DB modifications are applied immediately, or during the maintenance window"
  type        = bool
  default     = true
}
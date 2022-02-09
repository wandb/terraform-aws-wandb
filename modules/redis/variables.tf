variable "namespace" {
  type        = string
  description = "(Required) The name prefix for all resources created."
}

variable "preferred_maintenance_window" {
  description = "(Optional) The weekly time range during which system maintenance can occur, in (UTC)"
  type        = string
  default     = "sun:03:00-sun:04:00"
}

variable "redis_subnet_group_name" {
  description = "The name of the subnet group (existing)"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "The identity of the VPC in which the security group attached to elasticache will be deployed."
  type        = string
}

variable "vpc_subnets_cidr_blocks" {
  description = "A list of CIDR blocks which are allowed to access elasticache"
  type = list(string)
  default = []
}

variable "kms_key_arn" {
  description = "The ARN for the KMS encryption key."
  type        = string
}
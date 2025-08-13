variable "key_alias" {
  description = "The key alias for AWS KMS Customer managed key."
  type        = string
}

variable "key_deletion_window" {
  description = "Duration in days to destroy the key after it is deleted. Must be between 7 and 30 days."
  type        = number
}

variable "iam_principal_arn" {
  description = "The IAM principal (role or user) ARN that will be authorized to use the key."
  type        = string
  default     = ""
}

variable "policy_administrator_arn" {
  description = "The IAM principal (role or user) ARN that will be authorized to manage the key."
  type        = string
  default     = ""
}

variable "key_policy" {
  description = "The policy that will define the permissions for the kms key."
  type        = string
  default     = ""
}

variable "create_clickhouse_key" {
  description = "Whether to create a KMS key for Clickhouse CMEK."
  type        = bool
  default     = false
}

variable "clickhouse_key_alias" {
  description = "The key alias for AWS KMS Customer managed key."
  type        = string
  default     = "wandb-kms-clickhouse-key"
}

variable "clickhouse_key_policy" {
  description = "The policy that will define the permissions for the kms clickhouse key."
  type        = string
  default     = ""
}

variable "clickhouse_tde_arn" {
  description = "The ARN TDE string to allow Clickhouse encryption."
  type        = string
  default     = ""
}

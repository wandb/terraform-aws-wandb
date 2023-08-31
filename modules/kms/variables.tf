variable "key_alias" {
  description = "The key alias for AWS KMS Customer managed key."
  type        = string
}

variable "key_deletion_window" {
  description = "Duration in days to destroy the key after it is deleted. Must be between 7 and 30 days."
  type        = number
}

variable "enable_key_rotation" {
  description = "Specifies whether key rotation is enabled. https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html"
  type        = bool
  default     = true
}

variable "iam_principal_arn" {
  description = "The IAM principal (role or user) ARN that will be authorized to use the key."
  type        = string
  default     = ""
}

variable "key_policy" {
  description = "The policy that will define the permissions for the kms key."
  type        = string
  default     = ""
}

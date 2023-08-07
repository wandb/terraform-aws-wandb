variable "namespace" {
  type        = string
  description = "Prefix to use when creating resources"
}

variable "create_kms_key" {
  description = "If a KMS key should be created to encrypt S3 storage bucket objects. This can only be used when you set the value of sse_algorithm as aws:kms."
  type        = bool
  default     = false
}

variable "sse_algorithm" {
  description = "The server-side encryption algorithm to use. Valid values are `AES256` and `aws:kms`"
  type        = string
  default     = "aws:kms"
}

variable "deletion_protection" {
  description = "If the bucket should have deletion protection enabled."
  type        = bool
  default     = false
}

variable "aws_principal_arn" {
  description = "AWS principal that can access the bucket"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS Key to use if key creation is disabled."
  type        = string
  default     = ""
}
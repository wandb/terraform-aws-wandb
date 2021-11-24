variable "namespace" {
  type        = string
  description = "(Required) Friendly name prefix used for tagging and naming AWS resources."
}

variable "kms_key_arn" {
  description = "(Required) The Amazon Resource Name of the KMS key with which S3 storage bucket objects will be encrypted."
  type        = string
}

variable "deletion_protection" {
  description = "If the DB instance should have deletion protection enabled. The database can't be deleted when this value is set to `true`."
  type        = bool
  default     = true
}
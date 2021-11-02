variable "namespace" {
  type        = string
  description = "(Required) Friendly name prefix used for tagging and naming AWS resources."
}

variable "kms_key_arn" {
  description = "(Required) The Amazon Resource Name of the KMS key with which S3 storage bucket objects will be encrypted."
  type        = string
}
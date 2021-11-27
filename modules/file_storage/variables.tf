variable "namespace" {
  type        = string
  description = "Friendly name prefix used for tagging and naming AWS resources."
}

variable "sse_algorithm" {
  description = "The server-side encryption algorithm to use. Valid values are `AES256` and `aws:kms`"
  type        = string
  default     = "aws:kms"
}

variable "kms_key_arn" {
  description = "The Amazon Resource Name of the KMS key with which S3 storage bucket objects will be encrypted. The AWS KMS master key ID used for the SSE-KMS encryption. This can only be used when you set the value of sse_algorithm as aws:kms."
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "If the DB instance should have deletion protection enabled. The database can't be deleted when this value is set to `true`."
  type        = bool
  default     = true
}

variable "create_queue" {
  description = "Creates a SQS queue for the bucket"
  type        = bool
  default     = true
}

variable "create_queue_policy" {
  description = "Create a SQS policy for bucket access."
  type        = bool
  default     = true
}
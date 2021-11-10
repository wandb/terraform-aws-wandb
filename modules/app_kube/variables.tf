variable "namespace" {
  type        = string
  description = "(Required) The name prefix for all resources created."
}

variable "wandb_version" {
  description = "(Optional) The version of Weights & Biases local to deploy."
  type        = string
  default     = "latest"
}

variable "wandb_license" {
  description = "(Optional) The license for deploying Weights & Biases local."
  type        = string
  default     = null
}

variable "wandb_image" {
  description = "(Optional) Docker repository of to pull the wandb image from."
  type        = string
  default     = "wandb/local"
}

variable "bucket_name" {
  type        = string
  description = "(Required) The S3 bucket for storing data"
}

variable "bucket_region" {
  type        = string
  description = "(Required) Region where the bucket lives"
}

variable "bucket_kms_key_arn" {
  description = "(Optional) The ARN for the KMS encryption key if one is required for storage descryption."
  type        = string
  default     = ""
}

variable "bucket_queue_name" {
  type        = string
  description = "(Required) The SQS queue for object creation events."
}

variable "database_connection_string" {
  type = string
}

variable "host" {
  type        = string
  description = "The FQD of your instance, i.e. https://my.domain.net"
  default     = ""
}

variable "service_port" {
  type    = number
  default = 32543
}
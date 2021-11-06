variable "namespace" {
  type        = string
  description = "(Required) The name prefix for all resources created."
}

variable "kms_key_arn" {
  type        = string
  description = " The Amazon Resource Name of the KMS key with which S3 storage bucket objects will be encrypted."
  default     = null
}

variable "wandb_version" {
  description = "The version of Weights & Biases local to deploy."
  type        = string
  default     = "latest"
}

variable "wandb_license" {
  description = "The license for deploying Weights & Biases local."
  type        = string
  default     = null
}

variable "wandb_image" {
  description = "Docker repository of to pull the wandb image from."
  type        = string
  default     = "wandb/local"
}

variable "bucket_name" {
  type = string
}

variable "bucket_queue_name" {
  type = string
}

variable "bucket_region" {
  type        = string
  description = "Region where the bucket lives"
}

variable "database_endpoint" {
  type = string
}


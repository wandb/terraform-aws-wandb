variable "namespace" {
  type        = string
  description = "(Required) The name prefix for all resources created."
}

variable "local_version" {
  description = "The version of Weights & Biases local to deploy."
  type        = string
  default     = "latest"
}

variable "local_license" {
  description = "The license for deploying Weights & Biases local."
  type        = string
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

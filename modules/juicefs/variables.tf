variable "namespace" {
  description = "The name prefix for all resources created"
  nullable    = false
  type        = string
}

variable "security_group_ids" {
  description = "SGs to be added to this cluster"
  nullable    = false
  type        = list(string)
}

variable "s3_bucket_name" {
  description = "The name of the S3 bucket used to store chunk data"
  nullable    = false
  type        = string
}

variable "vpc_id" {
  description = "VPC id"
  nullable    = false
  type        = string
}
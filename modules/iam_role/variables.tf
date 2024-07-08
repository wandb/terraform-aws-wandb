variable "namespace" {
  type        = string
  description = "The name prefix for all resources created."
}

variable "aws_iam_openid_connect_provider_url" {
  type        = string
}

variable "yace_sa_name" {
  type = string
}
variable "namespace" {
  type        = string
  description = "(Required) The name prefix for all resources created."
}

variable "kms_key_arn" {
  description = "(Required) The Amazon Resource Name of the KMS key with which S3 storage bucket objects will be encrypted."
  type        = string
}

variable "network_id" {
  description = "(Required) The identity of the VPC in which the security group attached to the MySQL Aurora instances will be deployed."
  type        = string
}

variable "network_private_subnets" {
  description = "(Required) A list of the identities of the private subnetworks in which the MySQL Aurora instances will be deployed."
  type        = list(string)
}

variable "cluster_endpoint_public_access" {
  type        = bool
  description = "(Optional) Indicates whether or not the Amazon EKS public API server endpoint is enabled."
  default     = true
}

variable "lb_security_group_inbound_id" {
  type = string
}

variable "bucket_arn" {
  type = string
}

variable "bucket_sqs_queue_arn" {
  type = string
}

variable "database_security_group_id" {
  type = string
}

variable "service_port" {
  type    = number
  default = 32543
}
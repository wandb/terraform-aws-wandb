variable "elasticache_user" {
  description = "The username used to access elasticache"
  nullable    = false
  type        = string
}

variable "elasticache_password" {
  description = "Isn't it obvious?"
  nullable    = false
  type        = string
}


variable "k8s_cluster_id" {
  description = "The terraform id of the k8s cluster"
  nullable    = false
  type        = string
}

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

variable "subnet_ids" {
  description = "A list of subnet ids where the cluster will be deployed"
  nullable    = false
  type        = list(string)
}

variable "subnet_group_name" {
  description = "Name of the subnet group"
  nullable    = false
  type        = string
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
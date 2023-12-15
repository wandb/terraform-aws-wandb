variable "namespace" {
  description = "The namespace to use for the efs resource"
  type        = string
}

variable "private_subnets" {
  description = "A list of the subnets in which the aws_efs_mount_target will be deployed."
  type        = list(string)
}

variable "primary_workers_security_group_id" {
  description = "The security group ID of the primary workers."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC in which the storage_class_nfs security group will be deployed."
  type        = string
}

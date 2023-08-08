variable "namespace" {
  type        = string
  nullable    = false
  description = "The name prefix for all resources created"
}

variable "source_security_group_id" {
  type        = string
  nullable    = false
  description = "Id of security group to be added to the rules of the elasticache sg created by the juicefs module"
}

variable "subnet_ids" {
  type        = list(string)
  nullable    = false
  description = "IDs of subnets which comprise the subnet group"
}

variable "vpc_id" {
  type        = string
  nullable    = false
  description = "VPC id"
}
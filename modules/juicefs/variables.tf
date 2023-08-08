variable "namespace" {
  type        = string
  nullable    = false
  description = "The name prefix for all resources created"
}

variable "security_group_ids" {
  type        = string
  nullable    = false
  description = "Security groups which will be attached to the cluster"
}
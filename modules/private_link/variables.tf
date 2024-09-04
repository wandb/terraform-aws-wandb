variable "namespace" {
  description = "Namespace for naming resources"
  type        = string
}

variable "allowed_account_ids" {
  description = "List of AWS account IDs allowed to access the VPC Endpoint Service"
  type        = list(string)
}

variable "network_private_subnets" {
  description = "List of private subnets for the VPC"
  type        = list(string)
}

variable "deletion_protection" {
  description = "If the instance should have deletion protection enabled. The database / S3 can't be deleted when this value is set to `true`."
  type        = bool
}

variable "alb_name" {
  description = "Name of the ALB to forward NLB traffic to"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC to create the VPC Endpoint Service in"
  type        = string
}

variable "enable_private_only_traffic" {
  type = bool
}
variable "nlb_security_group" {
  type = string
}
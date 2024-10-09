
variable "namespace" {
  type        = string
  description = "(Required) String used for prefix resources."
}

variable "ssl_policy" {
  type        = string
  default     = "ELBSecurityPolicy-FS-1-2-Res-2020-10"
  description = "(Optional) SSL policy to use on ALB listener"
}

variable "allowed_inbound_cidr" {
  description = "CIDRs allowed to access wandb-server."
  type        = list(string)
  nullable    = false
}

variable "allowed_inbound_ipv6_cidr" {
  description = "CIDRs allowed to access wandb-server."
  type        = list(string)
  nullable    = false
}

variable "network_id" {
  description = "(Required) The identity of the VPC in which the security group attached to the MySQL Aurora instances will be deployed."
  type        = string
}

variable "private_endpoint_cidr" {
  description = "List of CIDR blocks allowed to access the wandb-server"
  type        = list(string)
}

variable "enable_private_only_traffic" {
  description = "Boolean flag to create sg"
  type        = bool
}

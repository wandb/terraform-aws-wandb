
variable "namespace" {
  type        = string
  description = "String used for prefix resources."
}

variable "load_balancing_scheme" {
  default     = "PRIVATE"
  description = "Load Balancing Scheme. Supported values are: \"PRIVATE\"; \"PUBLIC\"."
  type        = string

  validation {
    condition     = contains(["PRIVATE", "PUBLIC"], var.load_balancing_scheme)
    error_message = "The load_balancer_scheme value must be one of: \"PRIVATE\"; \"PUBLIC\"."
  }
}

variable "network_id" {
  description = "(Required) The identity of the VPC in which the security group attached to the MySQL Aurora instances will be deployed."
  type        = string
}

variable "network_private_subnets" {
  description = "(Required) A list of the identities of the private subnetworks in which the MySQL Aurora instances will be deployed."
  type        = list(string)
}

variable "network_public_subnets" {
  default     = []
  description = "A list of the identities of the public subnetworks in which resources will be deployed."
  type        = list(string)
}
variable "namespace" {
  type        = string
  description = "(Required) String used for prefix resources."
}

variable "network_private_subnets" {
  description = "(Required) A list of the identities of the private subnetworks in which the MySQL Aurora instances will be deployed."
  type        = list(string)
}

variable "private_dns" {
    type    = string
    default = null
}

variable "create_private_dns_records" {
   type = bool
   default false
}

variable "deletion_protection" {
  description = "If the instance should have deletion protection enabled. The database / S3 can't be deleted when this value is set to `true`."
  type        = bool
  default     = true
}
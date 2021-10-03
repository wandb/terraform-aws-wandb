variable "namespace" {
  type        = string
  description = "(Required) String used for prefix resources."
}

variable "domain_name" {
  type        = string
  description = "(Required) Domain for creating the Weights & Biases subdomain on."
}

variable "subdomain" {
  type        = string
  default     = "wandb"
  description = "(Required) Subdomain for accessing the Weights & Biases UI."
}

variable "is_subdomain_zone" {
  type        = bool
  default     = false
  description = "(Optional) Using Amazon Route 53 as the DNS service for only a subdomain of the parent."
}

variable "acm_certificate_arn" {
  type        = string
  default     = null
  description = "(Optional) The ARN of an existing ACM certificate. If one is not provided, one will be create."
}
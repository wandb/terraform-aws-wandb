variable "namespace" {
  type = string
}

variable "oidc_provider" {
  type = object({
    arn = string
    url = string
  })
}

variable "fqdn" {
  type = string
}

variable "enable_external_dns" {
  description = "Whether to enable the external dns addon"
  type        = bool
  default     = true
}

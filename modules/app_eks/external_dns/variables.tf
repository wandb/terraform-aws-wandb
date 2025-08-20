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
variable "external_dns_image" {
  type        = string
  description = "The image repository of the external-dns to deploy."
  default     = "registry.k8s.io/external-dns/external-dns"
}

variable "external_dns_version" {
  type        = string
  description = "The tag of the external-dns to deploy."
  default     = null
}

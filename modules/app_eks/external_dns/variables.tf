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

variable "subject_alternative_names" {
  type = list(string)
}

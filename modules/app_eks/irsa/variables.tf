variable "oidc_provider" {
  type = object({
    arn = string
    url = string
  })
}

variable "namespace" {
  type = string
}

variable "role_name" {
  type = string
}

variable "policy_name" {
  type = string
}

variable "path" {
  type = string
}
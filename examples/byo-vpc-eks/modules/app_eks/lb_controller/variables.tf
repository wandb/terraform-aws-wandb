variable "namespace" {
  type = string
}

variable "oidc_provider" {
  type = object({
    arn = string
    url = string
  })
}

variable "aws_loadbalancer_controller_tags" {
  type = map(string)
}

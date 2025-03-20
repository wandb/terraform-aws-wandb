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

variable "enable_aws_loadbalancer_controller" {
  description = "Whether to enable the AWS Load Balancer Controller addon"
  type        = bool
  default     = true
}

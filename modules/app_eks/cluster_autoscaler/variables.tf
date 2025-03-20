variable "namespace" {
  type = string
}

variable "oidc_provider" {
  type = object({
    arn = string
    url = string
  })
}

variable "enable_cluster_autoscaler" {
  description = "Whether to enable the cluster autoscaler addon"
  type        = bool
  default     = true
}

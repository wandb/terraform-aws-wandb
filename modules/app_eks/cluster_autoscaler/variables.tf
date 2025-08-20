variable "namespace" {
  type = string
}

variable "oidc_provider" {
  type = object({
    arn = string
    url = string
  })
}

variable "cluster_autoscaler_image" {
  type        = string
  description = "The image repository of the external-dns to deploy."
  default     = "registry.k8s.io/autoscaling/cluster-autoscaler"
}

variable "cluster_autoscaler_version" {
  type        = string
  description = "The tag of the cluster-autoscaler to deploy."
  default     = "v1.31.0"
}
variable "namespace" {
  type = string
}

variable "oidc_provider" {
  type = object({
    arn = string
    url = string
  })
}

variable "k8s_namespace" {
  type        = string
  description = "The Kubernetes namespace where W&B resources will be deployed"
}

variable "secrets_store_csi_driver_version" {
  type        = string
  description = "The version of the Secrets Store CSI Driver Helm chart to install."
}

variable "secrets_store_csi_driver_provider_aws_version" {
  type        = string
  description = "The version of the AWS Secrets Manager Provider for Secrets Store CSI Driver Helm chart to install."
}

variable "weave_worker_auth_secret_name" {
  type        = string
  description = "The name of the AWS Secrets Manager secret for weave worker auth"
}

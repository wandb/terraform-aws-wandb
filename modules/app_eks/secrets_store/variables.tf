variable "secrets_store_csi_driver_version" {
  type        = string
  description = "The version of the Secrets Store CSI Driver Helm chart to install."
}

variable "secrets_store_csi_driver_provider_aws_version" {
  type        = string
  description = "The version of the AWS Secrets Manager Provider for Secrets Store CSI Driver Helm chart to install."
}

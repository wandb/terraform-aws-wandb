variable "auth0_domain" {
  type        = string
  description = "The Auth0 domain of your tenant"
  nullable    = true
}

variable "auth0_client_id" {
  type        = string
  description = "The Auth0 Client ID of application"
  nullable    = true
}

variable "cloud_monitoring_connection_string" {
  type        = string
  description = "The cloud provider to publish custom system metrics to for monitoring. Possible values are s3://, gs://, or az://."
  default     = "noop://"
  nullable    = false
}

variable "database_connection_string" {
  type        = string
  description = "The MySQL connection string."
  nullable    = false
}

variable "fqdn" {
  type        = string
  description = "FQDN of the installation"
  nullable    = false
}

variable "license" {
  description = "Your wandb license key"
  nullable    = true
  type        = string
}

variable "local_restore" {
  description = "(bool) Restores Weights & Biases to a stable state if needed."
  nullable    = false
  type        = bool
}

variable "namespace" {
  description = "The name prefix for all resources created"
  nullable    = false
  type        = string
}

variable "oidc_issuer" {
  type        = string
  description = "A url to your Open ID Connect identity provider, i.e. https://cognito-idp.us-east-1.amazonaws.com/us-east-1_uiIFNdacd"
  nullable    = true
}

variable "oidc_client_id" {
  type        = string
  description = "The Client ID of application in your identity provider"
  nullable    = true
}

variable "oidc_secret" {
  type        = string
  description = "The Client secret of the application in your identity provider"
  nullable    = true
  sensitive   = true
}

variable "oidc_auth_method" {
  type        = string
  description = "OIDC auth method"
  nullable    = false
  default     = "implicit"
  validation {
    condition     = contains(["pkce", "implicit"], var.oidc_auth_method)
    error_message = "Invalid OIDC auth method."
  }
}

variable "other_wandb_env" {
  type     = map(string)
  nullable = false
}

variable "parquet_service_name" {
  type        = string
  nullable    = true
  description = "The name of the parquet service, used to inform wandb where parquet lives."
}

variable "redis_connection_string" {
  type        = string
  description = "The redis connection string."
  nullable    = false
}

variable "redis_ca_cert" {
  type        = string
  description = "The redis certificate authority."
  nullable    = true
}

variable "resource_requests" {
  type        = map(string)
  description = "Specifies the allocation for resource requests"
  nullable    = false
  default = {
    cpu    = "500m"
    memory = "1G"
  }
}

variable "resource_limits" {
  type        = map(string)
  description = "Specifies the allocation for resource limits"
  nullable    = false
  default = {
    cpu    = "4000m"
    memory = "8G"
  }
}

variable "region" {
  type        = string
  description = "The region your VPC is in."
  nullable    = false
}

variable "s3_bucket_kms_key_arn" {
  type        = string
  description = "AWS KMS key used to decrypt the bucket."
  nullable    = true
}

variable "s3_bucket_name" {
  description = "The name of the S3 bucket used to store chunk data"
  nullable    = false
  type        = string
}

variable "s3_bucket_queue" {
  type        = string
  nullable    = true
  description = "The SQS/Google PubSub queue for object creation events"
}

variable "vpc_id" {
  description = "VPC id"
  nullable    = false
  type        = string
}

variable "weave_service_name" {
  type        = string
  nullable    = true
  description = "The name of the weave service, used to inform wandb where weave lives."
}
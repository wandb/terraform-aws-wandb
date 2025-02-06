variable "cloudtrail_bucket_name" {
  description = "The name of the S3 bucket for CloudTrail logs"
  type        = string
}

variable "force_destroy" {
  description = "Flag to determine if the bucket should be forcefully deleted"
  type        = bool
  default     = false
}

variable "log_lifecycle" {
  description = "Lifecycle configuration for CloudTrail logs"
  type = object({
    transition_days = number
    expiration_days = number
  })
}

variable "include_global_service_events" {
  description = "Whether to include global service events in the CloudTrail"
  type        = bool
  default     = true
}

variable "multi_region_trail" {
  description = "Whether to enable CloudTrail across multiple regions"
  type        = bool
  default     = true
}

variable "enable_log_file_validation" {
  description = "Whether to enable log file validation in CloudTrail"
  type        = bool
  default     = true
}

variable "namespace" {
  description = "The namespace for this specific deployment"
  type        = string
}

variable "tags" {
  description = "A map of tags to be applied to resources"
  type        = map(string)
  default     = {}
}

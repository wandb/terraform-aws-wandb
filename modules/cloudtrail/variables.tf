variable "enable_cloudtrail_s3_logging" {
  description = "Enable or disable CloudTrail logging for S3 events"
  type        = bool
  default     = false
}

variable "cloudtrail_bucket_name" {
  description = "Name of the S3 bucket for storing CloudTrail logs specific to S3 events"
  type        = string
  default     = "cloudtrail-s3-events-logs-bucket"
}

variable "keep_cloudtrail_bucket" {
  description = "Controls whether S3 bucket storing Cloudtrail Logs will be kept"
  type        = bool
  default     = true
}

variable "multi_region_trail" {
  description = "Enable multi-region CloudTrail logging"
  type        = bool
  default     = true
}

variable "include_global_service_events" {
  description = "Include global service events in CloudTrail logs"
  type        = bool
  default     = true
}

variable "enable_log_file_validation" {
  description = "Enable CloudTrail log file validation"
  type        = bool
  default     = true
}

variable "log_lifecycle" {
  description = "Configuration for lifecycle policies on the CloudTrail logs bucket"
  type = object({
    transition_days = number
    expiration_days = number
  })
  default = {
    transition_days = 90
    expiration_days = 730
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "production"
  }
}
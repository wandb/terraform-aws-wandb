##########
## the variables defined herein are used to tag resources
## in Datadog, and solely for that purpose
##########

variable "cloud_provider_tag" {
  nullable = false
  type = string

  validation {
    condition = contains(["aws", "azure", "gcp", "none"], var.cloud_provider_tag)
    error_message = "cloud_provider must be set to one of 'aws', 'azure', or 'gcp'"
  }
}

variable "database_tag" {
    nullable = false
    type = string

    validation {
      condition = contains(["embedded", "byodb", "managed", "saas" ], var.database_tag)
      error_message = "See 'Datadog Tagging Best Practices' in Notion."
    }
}

variable "environment_tag" {
    nullable = false
    type = string

    validation {
      condition = contains(["local", "managed-install", "on-prem", "production", "qa" ], var.environment_tag)
      error_message = "See 'Datadog Tagging Best Practices' in Notion."
    }
}

variable "objectstore_tag" {
    nullable = false
    type = string

    validation {
      condition = contains(["embedded", "byob", "managed", "saas" ], var.objectstore_tag)
      error_message = "See 'Datadog Tagging Best Practices' in Notion."
    }
}
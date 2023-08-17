variable "fqdn" {
  type        = string
  description = "The FQD of your instance."
  nullable    = false
}

variable "dd_env" {
  type        = string
  description = "The Datadog environment to send metrics to."
  nullable    = false
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
    cpu    = "8000m"
    memory = "16G"
  }
}
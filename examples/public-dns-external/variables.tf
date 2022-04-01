variable "namespace" {
  type        = string
  description = "Name prefix used for resources"
}

variable "domain_name" {
  type        = string
  description = "Domain name used to access instance."
}

variable "zone_id" {
  type        = string
  description = "Id of Route53 zone"
}

variable "subdomain" {
  type        = string
  default     = null
  description = "Subdomain for accessing the Weights & Biases UI."
}

variable "wandb_license" {
  type = string
}

variable "database_engine_version" {
  description = "Version for MySQL Auora"
  type        = string
  default     = "5.7"

  validation {
    condition     = contains(["5.7", "8.0.mysql_aurora.3.01.0"], var.database_engine_version)
    error_message = "We only support MySQL: \"5.7\"; \"8.0.mysql_aurora.3.01.0\"."
  }
}
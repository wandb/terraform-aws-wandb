variable "namespace" {
  type        = string
  description = "Name prefix used for resources"
}

variable "domain" {
  type        = string
  default     = "wandb"
  description = "Subdomain for accessing the Weights & Biases UI."
}

variable "subdomain" {
  type        = string
  default     = "wandb"
  description = "Subdomain for accessing the Weights & Biases UI."
}

variable "wandb_license" {
  type = string
}

variable "zone_id" {
  description = "The Route53 zone ID to create records in."
  type        = string
}

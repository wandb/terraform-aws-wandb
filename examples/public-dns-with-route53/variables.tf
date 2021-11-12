variable "namespace" {
  type        = string
  description = "Name prefix used for resources"
}

variable "domain_name" {
  type        = string
  description = "Domain zone for creating the Weights & Biases subdomain on."
}

variable "subdomain" {
  type        = string
  default     = "wandb"
  description = "Subdomain for accessing the Weights & Biases UI."
}

variable "license" {
  type = string
}
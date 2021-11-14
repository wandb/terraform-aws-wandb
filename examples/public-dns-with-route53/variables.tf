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

variable "license" {
  type = string
}
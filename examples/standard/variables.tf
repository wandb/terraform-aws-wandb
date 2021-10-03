variable "namespace" {
  type        = string
  description = "Name prefix used for resources"
}

variable "domain_name" {
  type        = string
  description = "Domain for creating the Terraform Enterprise subdomain on."
}

variable "subdomain" {
  type        = string
  default     = "wandb"
  description = "Subdomain for accessing the Weights & Biases UI."
}
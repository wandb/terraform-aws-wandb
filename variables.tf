##########################################
# Common                                 #
##########################################
variable "namespace" {
  type        = string
  description = "String used for prefix resources."
}

variable "wandb_version" {
  description = "The version of Weights & Biases local to deploy."
  type        = string
  default     = "latest"
}

variable "wandb_license" {
  description = "The license for deploying Weights & Biases local."
  type        = string
  default     = null
}

variable "wandb_image" {
  description = "Docker repository of to pull the wandb image from."
  type        = string
  default     = "wandb/local"
}

##########################################
# DNS                                    #
##########################################
variable "is_subdomain_zone" {
  type        = bool
  default     = false
  description = "(Optional) Using Amazon Route 53 as the DNS service for only a subdomain of the parent."
}

variable "domain_name" {
  type        = string
  description = "Domain for creating the Weights & Biases subdomain on."
}

variable "subdomain" {
  type        = string
  default     = "wandb"
  description = "Subdomain for accessing the Weights & Biases UI."
}

##########################################
# Load Balancer                          #
##########################################
variable "load_balancing_scheme" {
  default     = "PRIVATE"
  description = "Load Balancing Scheme. Supported values are: \"PRIVATE\"; \"PRIVATE_TCP\"; \"PUBLIC\"."
  type        = string

  validation {
    condition     = contains(["PRIVATE", "PRIVATE_TCP", "PUBLIC"], var.load_balancing_scheme)
    error_message = "The load_balancer value must be one of: \"PRIVATE\"; \"PRIVATE_TCP\"; \"PUBLIC\"."
  }
}

variable "ssl_policy" {
  type        = string
  default     = "ELBSecurityPolicy-2016-08"
  description = "SSL policy to use on ALB listener"
}

variable "acm_certificate_arn" {
  type        = string
  default     = null
  description = "The ARN of an existing ACM certificate."
}

variable "allowed_inbound_cidr" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "(Optional) Allow HTTP(S) traffic to W&B. Defaults to all connections."
}

##########################################
# KMS                                    #
##########################################
variable "kms_key_alias" {
  type        = string
  description = "KMS key alias for AWS KMS Customer managed key."
  default     = "wandb-managed-kms"
}

variable "kms_key_deletion_window" {
  type        = number
  description = "(Optional) Duration in days to destroy the key after it is deleted. Must be between 7 and 30 days."
  default     = 7
}


##########################################
# Network                                #
##########################################
variable "deploy_vpc" {
  type        = bool
  description = "(Optional) Boolean indicating whether to deploy a VPC (true) or not (false)."
  default     = true
}

variable "network_id" {
  default     = ""
  description = "The identity of the VPC in which resources will be deployed."
  type        = string
}

variable "network_private_subnets" {
  default     = []
  description = "A list of the identities of the private subnetworks in which resources will be deployed."
  type        = list(string)
}

variable "network_public_subnets" {
  default     = []
  description = "(Optional) A list of the identities of the public subnetworks in which resources will be deployed."
  type        = list(string)
}

variable "network_cidr" {
  type        = string
  description = "(Optional) CIDR block for VPC."
  default     = "10.0.0.0/16"
}

variable "network_private_subnet_cidrs" {
  type        = list(string)
  description = "(Optional) List of private subnet CIDR ranges to create in VPC."
  default     = ["10.0.32.0/20", "10.0.48.0/20"]
}

variable "network_public_subnet_cidrs" {
  type        = list(string)
  description = "(Optional) List of public subnet CIDR ranges to create in VPC."
  default     = ["10.0.0.0/20", "10.0.16.0/20"]
}
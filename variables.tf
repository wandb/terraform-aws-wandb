##########################################
# Common                                 #
##########################################
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
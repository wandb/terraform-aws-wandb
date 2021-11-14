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
variable "public_access" {
  type        = bool
  default     = false
  description = "(Optional) Is this instance accessable a public domain."
}

variable "external_dns" {
  type        = bool
  default     = false
  description = "(Optional) Using external DNS. A `subdomain` must also be specified if this value is true."
}

# Sometimes domain name and zone name dont match, so lets explicitly ask for
# both. Also is just life easier to have both even though in most cause it may
# be redundant info.
# https://github.com/hashicorp/terraform-aws-terraform-enterprise/pull/41#issuecomment-563501858
variable "zone_id" {
  type        = string
  description = "(Required) Domain for creating the Weights & Biases subdomain on."
}

variable "domain_name" {
  type        = string
  description = "(Required) Domain for accessing the Weights & Biases UI."
}

variable "subdomain" {
  type        = string
  default     = null
  description = "(Optional) Subdomain for accessing the Weights & Biases UI. Default creates record at Route53 Route."
}

##########################################
# Load Balancer                          #
##########################################
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

variable "allowed_inbound_ipv6_cidr" {
  type        = list(string)
  default     = ["::/0"]
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
variable "create_vpc" {
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

variable "network_private_subnets" {
  type        = list(string)
  description = "(Optional) A list of public subnets inside the VPC."
  default     = ["10.0.32.0/20", "10.0.48.0/20"]
}

variable "network_public_subnets" {
  type        = list(string)
  description = "(Optional) A list of private subnets inside the VPC."
  default     = ["10.0.0.0/20", "10.0.16.0/20"]
}


##########################################
# EKS Cluster                            #
##########################################
variable "kubernetes_public_access" {
  type        = bool
  description = "(Optional) Indicates whether or not the Amazon EKS public API server endpoint is enabled."
  default     = true
}

##########################################
# Bring Your Own Bucket                  #
##########################################
variable "byob" {
  type    = bool
  default = false
}

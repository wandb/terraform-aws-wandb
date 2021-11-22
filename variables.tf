##########################################
# Common                                 #
##########################################
variable "namespace" {
  type        = string
  description = "String used for prefix resources."
}

##########################################
# DNS                                    #
##########################################
variable "public_access" {
  type        = bool
  default     = false
  description = "Is this instance accessable a public domain."
}

variable "external_dns" {
  type        = bool
  default     = false
  description = "Using external DNS. A `subdomain` must also be specified if this value is true."
}

# Sometimes domain name and zone name dont match, so lets explicitly ask for
# both. Also is just life easier to have both even though in most cause it may
# be redundant info.
# https://github.com/hashicorp/terraform-aws-terraform-enterprise/pull/41#issuecomment-563501858
variable "zone_id" {
  type        = string
  description = "Domain for creating the Weights & Biases subdomain on."
}

variable "domain_name" {
  type        = string
  description = "Domain for accessing the Weights & Biases UI."
}

variable "subdomain" {
  type        = string
  default     = null
  description = "Subdomain for accessing the Weights & Biases UI. Default creates record at Route53 Route."
}

##########################################
# Load Balancer                          #
##########################################
variable "ssl_policy" {
  type        = string
  default     = "ELBSecurityPolicy-FS-1-2-Res-2020-10"
  description = "SSL policy to use on ALB listener"
}

variable "acm_certificate_arn" {
  type        = string
  default     = null
  description = "The ARN of an existing ACM certificate."
}

variable "allowed_inbound_cidr" {
  type        = list(string)
  default     = []
  description = "Allow HTTP(S) traffic to W&B. Defaults to no connections."
}

variable "allowed_inbound_ipv6_cidr" {
  type        = list(string)
  default     = []
  description = "Allow HTTP(S) traffic to W&B. Defaults to no connections."
}


##########################################
# KMS                                    #
##########################################
variable "kms_key_alias" {
  type        = string
  description = "KMS key alias for AWS KMS Customer managed key."
  default     = null
}

variable "kms_key_deletion_window" {
  type        = number
  description = "Duration in days to destroy the key after it is deleted. Must be between 7 and 30 days."
  default     = 7
}


##########################################
# Network                                #
##########################################
variable "create_vpc" {
  type        = bool
  description = "Boolean indicating whether to deploy a VPC (true) or not (false)."
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
  description = "A list of the identities of the public subnetworks in which resources will be deployed."
  type        = list(string)
}

variable "network_database_subnets" {
  default     = []
  description = "A list of the identities of the database subnetworks in which resources will be deployed."
  type        = list(string)
}

variable "network_cidr" {
  type        = string
  description = "CIDR block for VPC."
  default     = "10.0.0.0/16"
}

variable "network_public_subnet_cidrs" {
  type        = list(string)
  description = "List of private subnet CIDR ranges to create in VPC."
  default     = ["10.10.0.0/24", "10.10.1.0/24"]
}

variable "network_private_subnet_cidrs" {
  type        = list(string)
  description = "List of private subnet CIDR ranges to create in VPC."
  default     = ["10.10.10.0/24", "10.10.11.0/24"]
}

variable "network_database_subnet_cidrs" {
  type        = list(string)
  description = "List of private subnet CIDR ranges to create in VPC."
  default     = ["10.10.20.0/24", "10.10.21.0/24"]
}


##########################################
# EKS Cluster                            #
##########################################
variable "kubernetes_public_access" {
  type        = bool
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled."
  default     = true
}

variable "kubernetes_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint."
  type        = list(string)
  default     = []
}

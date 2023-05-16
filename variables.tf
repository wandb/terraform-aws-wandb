##########################################
# Common                                 #
##########################################
variable "namespace" {
  type        = string
  description = "String used for prefix resources."
}

variable "deletion_protection" {
  description = "If the instance should have deletion protection enabled. The database / S3 can't be deleted when this value is set to `true`."
  type        = bool
  default     = true
}

variable "use_internal_queue" {
  type    = bool
  default = false
}

##########################################
# Database                               #
##########################################
variable "database_engine_version" {
  description = "Version for MySQL Auora"
  type        = string
  default     = "8.0.mysql_aurora.3.03.0"
}

variable "database_instance_class" {
  description = "Instance type to use by database master instance."
  type        = string
  default     = "db.r5.large"
}

variable "database_snapshot_identifier" {
  description = "Specifies whether or not to create this cluster from a snapshot. You can use either the name or ARN when specifying a DB cluster snapshot, or the ARN when specifying a DB snapshot"
  type        = string
  default     = null
}

variable "database_sort_buffer_size" {
  description = "Specifies the sort_buffer_size value to set for the database"
  type        = number
  default     = 262144
}

variable "database_name" {
  description = "Specifies the name of the database"
  type        = string
  default     = "wandb_local"
}

variable "database_master_username" {
  description = "Specifies the master_username value to set for the database"
  type        = string
  default     = "wandb"
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

variable "extra_fqdn" {
  type    = list(string)
  default = []
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

variable "kms_key_policy" {
  type        = string
  description = "The policy that will define the permissions for the kms key."
  default     = ""
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
  default     = "10.10.0.0/16"
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

variable "network_elasticache_subnet_cidrs" {
  type        = list(string)
  description = "List of private subnet CIDR ranges to create in VPC."
  default     = ["10.10.30.0/24", "10.10.31.0/24"]
}


##########################################
# EKS Cluster                            #
##########################################
variable "eks_cluster_version" {
  type        = string
  description = "Indicates EKS cluster version"
  default     = "1.21"
}

variable "kubernetes_public_access" {
  type        = bool
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled."
  default     = false
}

variable "kubernetes_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint."
  type        = list(string)
  default     = []
}

variable "kubernetes_map_accounts" {
  description = "Additional AWS account numbers to add to the aws-auth configmap."
  type        = list(string)
  default     = []
}

variable "kubernetes_map_roles" {
  description = "Additional IAM roles to add to the aws-auth configmap."
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "kubernetes_map_users" {
  description = "Additional IAM users to add to the aws-auth configmap."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "kubernetes_instance_types" {
  description = "EC2 Instance type for primary node group."
  type        = list(string)
  default     = ["m4.large"]
 }

variable "eks_policy_arns" {
  type        = list(string)
  description = "Additional IAM policy to apply to the EKS cluster"
  default     = []
}

##########################################
# External Bucket                        #
##########################################
# Most users will not need these settings. They are ment for users who want a
# bucket and sqs that are in a different account.
variable "create_bucket" {
  type    = bool
  default = true
}

variable "bucket_name" {
  type    = string
  default = ""
}

variable "bucket_kms_key_arn" {
  type        = string
  description = "The Amazon Resource Name of the KMS key with which S3 storage bucket objects will be encrypted."
  default     = ""
}

##########################################
# Redis                                  #
##########################################
variable "create_elasticache" {
  type        = bool
  description = "Boolean indicating whether to provision an elasticache instance (true) or not (false)."
  default     = false
}

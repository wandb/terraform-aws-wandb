# ##########################################
# # Common                                 #
# ##########################################
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

variable "size" {
  description = "Deployment size for the instance"
  type        = string
  default     = "small"
}

##########################################
# Operator                               #
##########################################
variable "operator_chart_version" {
  type        = string
  description = "Version of the operator chart to deploy"
  default     = "1.3.4"
}

variable "controller_image_tag" {
  type        = string
  description = "Tag of the controller image to deploy"
  default     = "1.14.0"
}

##########################################
# Database                               #
##########################################
variable "database_engine_version" {
  description = "Version for MySQL Aurora"
  type        = string
  default     = "8.0.mysql_aurora.3.07.1"
}

variable "database_instance_class" {
  description = "Instance type to use by database master instance. Defaults to null and value from deployment-size.tf is used"
  type        = string
  default     = null
}

variable "database_snapshot_identifier" {
  description = "Specifies whether or not to create this cluster from a snapshot. You can use either the name or ARN when specifying a DB cluster snapshot, or the ARN when specifying a DB snapshot"
  type        = string
  default     = null
}

variable "database_sort_buffer_size" {
  description = "Specifies the sort_buffer_size value to set for the database"
  type        = number
  default     = 67108864
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

variable "database_binlog_format" {
  description = "Specifies the binlog_format value to set for the database"
  type        = string
  default     = "ROW"
}

variable "database_innodb_lru_scan_depth" {
  description = "Specifies the innodb_lru_scan_depth value to set for the database"
  type        = number
  default     = 128
}

variable "database_performance_insights_kms_key_arn" {
  default     = ""
  description = "Specifies an existing KMS key ARN to encrypt the performance insights data if performance_insights_enabled is was enabled out of band"
  nullable    = true
  type        = string
}
variable "database_kms_key_arn" {
  type    = string
  default = ""
  validation {
    condition     = can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]+:key/[a-zA-Z0-9-_]+$", var.database_kms_key_arn)) || var.database_kms_key_arn == ""
    error_message = "Invalid value for db kms ARN"
  }
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

variable "custom_domain_filter" {
  description = "A custom domain filter to be used by external-dns instead of the default FQDN. If not set, the local FQDN is used."
  type        = string
  default     = null
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
  type        = list(string)
  description = "Additional fqdn's must be in the same hosted zone as `domain_name`."
  default     = []
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
  description = "CIDRs allowed to access wandb-server."
  nullable    = false
  type        = list(string)
}

variable "allowed_inbound_ipv6_cidr" {
  description = "CIDRs allowed to access wandb-server."
  nullable    = false
  type        = list(string)
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

variable "kms_key_policy_administrator_arn" {
  type        = string
  description = "The principal that will be allowed to manage the kms key."
  default     = ""
}

variable "kms_clickhouse_key_alias" {
  type        = string
  description = "KMS key alias for AWS KMS Customer managed key used by Clickhouse CMEK."
  default     = null
}

variable "kms_clickhouse_key_policy" {
  type        = string
  description = "The policy that will define the permissions for the clickhouse kms key."
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

variable "network_elasticache_subnets" {
  default     = []
  description = "A list of the identities of the subnetworks in which elasticache resources will be deployed."
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

variable "private_link_allowed_account_ids" {
  description = "List of AWS account IDs allowed to access the VPC Endpoint Service"
  type        = list(string)
  default     = []
}

variable "allowed_private_endpoint_cidr" {
  description = "Private CIDRs allowed to access wandb-server."
  nullable    = false
  type        = list(string)
  default     = []
}

variable "private_only_traffic" {
  description = "Enable private only traffic from customer private network"
  type        = bool
  default     = false
}

##########################################
# EKS Cluster                            #
##########################################
variable "eks_cluster_version" {
  description = "EKS cluster kubernetes version"
  nullable    = false
  type        = string
}
variable "kubernetes_alb_internet_facing" {
  type        = bool
  description = "Indicates whether or not the ALB controlled by the Amazon ALB ingress controller is internet-facing or internal."
  default     = true
}

variable "kubernetes_alb_subnets" {
  type        = list(string)
  description = "List of subnet ID's the ALB will use for ingress traffic."
  default     = []
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
  description = "EC2 Instance type for primary node group. Defaults to null and value from deployment-size.tf is used"
  type        = list(string)
  default     = null
}

variable "kubernetes_min_nodes_per_az" {
  description = "Minimum number of nodes for the EKS cluster. Defaults to null and value from deployment-size.tf is used"
  type        = number
  default     = null
}

variable "kubernetes_max_nodes_per_az" {
  description = "Maximum number of nodes for the EKS cluster. Defaults to null and value from deployment-size.tf is used"
  type        = number
  default     = null
}

variable "eks_policy_arns" {
  type        = list(string)
  description = "Additional IAM policy to apply to the EKS cluster"
  default     = []
}

variable "system_reserved_cpu_millicores" {
  description = "(Optional) The amount of 'system-reserved' CPU millicores to pass to the kubelet. For example: 100.  A value of -1 disables the flag."
  type        = number
  default     = 70
}

variable "system_reserved_memory_megabytes" {
  description = "(Optional) The amount of 'system-reserved' memory in megabytes to pass to the kubelet. For example: 100.  A value of -1 disables the flag."
  type        = number
  default     = 100
}

variable "system_reserved_ephemeral_megabytes" {
  description = "(Optional) The amount of 'system-reserved' ephemeral storage in megabytes to pass to the kubelet. For example: 1000.  A value of -1 disables the flag."
  type        = number
  default     = 750
}

variable "system_reserved_pid" {
  description = "(Optional) The amount of 'system-reserved' process ids [pid] to pass to the kubelet. For example: 1000.  A value of -1 disables the flag."
  type        = number
  default     = 500
}

variable "aws_loadbalancer_controller_tags" {
  description = "(Optional) A map of AWS tags to apply to all resources managed by the load balancer controller"
  type        = map(string)
  default     = {}
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
  type    = string
  default = ""
  validation {
    condition     = can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]+:key/[a-zA-Z0-9-_]+$", var.bucket_kms_key_arn)) || var.bucket_kms_key_arn == ""
    error_message = "Invalid value for bucket kms ARN"
  }
}

##########################################
# Bucket path                            #
##########################################
# This setting is meant for users who want to store all of their instance-level
# bucket's data at a specific path within their bucket. It can be set both for
# external buckets or the bucket created by this module.
variable "bucket_path" {
  description = "path of where to store data for the instance-level bucket"
  type        = string
  default     = ""
}

##########################################
# Redis                                  #
##########################################
variable "create_elasticache" {
  type        = bool
  description = "Boolean indicating whether to provision an elasticache instance (true) or not (false)."
  default     = true
}

variable "elasticache_node_type" {
  description = "The type of the redis cache node to deploy. Defaults to null and value from deployment-size.tf is used"
  type        = string
  default     = null
}

##########################################
# Weights & Biases                       #
##########################################
variable "license" {
  type        = string
  description = "Weights & Biases license key."
}

variable "other_wandb_env" {
  type        = map(any)
  description = "Extra environment variables for W&B"
  default     = {}
}

variable "weave_wandb_env" {
  type        = map(string)
  description = "Extra environment variables for W&B"
  default     = {}
}

variable "app_wandb_env" {
  type        = map(string)
  description = "Extra environment variables for W&B"
  default     = {}
}

variable "parquet_wandb_env" {
  type        = map(string)
  description = "Extra environment variables for W&B"
  default     = {}
}

variable "enable_yace" {
  type        = bool
  description = "deploy yet another cloudwatch exporter to fetch aws resources metrics"
  default     = true
}

variable "yace_sa_name" {
  type    = string
  default = "wandb-yace"
}

variable "enable_clickhouse" {
  type        = bool
  description = "Provision clickhouse resources"
  default     = false
}

variable "clickhouse_endpoint_service_id" {
  type        = string
  description = "The service ID of the VPC endpoint service for Clickhouse"
  default     = ""
}

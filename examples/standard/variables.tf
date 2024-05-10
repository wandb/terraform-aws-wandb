variable "namespace" {
  type        = string
  description = "String used for prefix resources."
}

variable "allowed_inbound_cidr" {
  description = "CIDRs allowed to access wandb-server."
  nullable    = false
  type        = list(string)
}

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
# Database                               #
##########################################
variable "database_engine_version" {
  description = "Version for MySQL Auora"
  type        = string
  default     = "8.0.mysql_aurora.3.05.2"
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
  default     = 67108864
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
# EKS Cluster                            #
##########################################
variable "eks_cluster_version" {
  description = "EKS cluster kubernetes version"
  nullable    = false
  type        = string
}

###########################################
#    Weights & Biases                     #
###########################################
variable "license" {
  type        = string
  description = "Weights & Biases license key."
}

variable "wandb_image" {
  description = "Docker repository of to pull the wandb image from."
  type        = string
  default     = "wandb/local"
}

variable "wandb_version" {
  description = "The version of Weights & Biases local to deploy."
  type        = string
  default     = "latest"
}

variable "other_wandb_env" {
  type        = map(string)
  description = "Extra environment variables for W&B"
  default     = {}
}
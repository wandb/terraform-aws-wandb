variable "region" {
  type        = string
  description = "Region to deploy resources"
  default     = "us-west-2"
}

variable "namespace" {
  type        = string
  description = "Name prefix used for resources"
}

variable "domain_name" {
  type        = string
  description = "Domain name used to access instance."
}

variable "zone_id" {
  type        = string
  description = "Id of Route53 zone"
}

variable "subdomain" {
  type        = string
  default     = null
  description = "Subdomain for accessing the Weights & Biases UI."
}

variable "wandb_license" {
  type = string
}

variable "database_engine_version" {
  description = "Version for MySQL Auora"
  type        = string
  default     = "8.0.mysql_aurora.3.07.1"
}

variable "database_instance_class" {
  description = "Instance type to use by database master instance."
  type        = string
  default     = "db.r6g.large"
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

variable "wandb_version" {
  description = "The version of Weights & Biases local to deploy."
  type        = string
  default     = "latest"
}

variable "kubernetes_instance_types" {
  description = "EC2 Instance type for primary node group."
  type        = list(string)
  default     = ["m5.large"]
}

variable "eks_cluster_version" {
  description = "EKS cluster kubernetes version"
  nullable    = false
  type        = string
  default     = "1.25"
}

variable "wandb_image" {
  description = "Docker repository of to pull the wandb image from."
  type        = string
  default     = "wandb/local"
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


variable "allowed_inbound_cidr" {
  default  = ["0.0.0.0/0"]
  nullable = false
  type     = list(string)
}


variable "allowed_inbound_ipv6_cidr" {
  default  = ["::/0"]
  nullable = false
  type     = list(string)
}

variable "other_wandb_env" {
  type        = map(string)
  description = "Extra environment variables for W&B"
  default     = {}
}

variable "vpc_id" {
  type        = string
  description = "VPC network ID"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC network CIDR"
}

variable "network_private_subnets" {
  type        = list(string)
  description = "Subnet IDs"
}


variable "enable_dummy_dns" {
  type        = bool
  description = "Enable dummy DNS"
  default     = false
}


variable "enable_operator_alb" {
  type        = bool
  description = "Enable operator ALB"
  default     = false
}

variable "network_public_subnets" {
  type        = list(string)
  description = "Subnet IDs"
}

variable "network_database_subnets" {
  type        = list(string)
  description = "Subnet IDs"
}

variable "network_private_subnet_cidrs" {
  type        = list(string)
  description = "Subnet CIDRs"
}

variable "network_public_subnet_cidrs" {
  type        = list(string)
  description = "Subnet CIDRs"
}

variable "network_database_subnet_cidrs" {
  type        = list(string)
  description = "Subnet CIDRs"
}

variable "network_elasticache_subnets" {
  type        = list(string)
  description = "Subnet CIDRs"
}

variable "network_elasticache_subnet_cidrs" {
  type        = list(string)
  description = "Subnet CIDRs"
}


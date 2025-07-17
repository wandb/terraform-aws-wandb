variable "namespace" {
  type        = string
  default     = "lsahu-wandb"
  description = "Name prefix used for resources"
}

variable "region" {
  type        = string
  default     = "us-west-2"
  description = "Region to deploy resources"
}

variable "domain_name" {
  type        = string
  default     = "wandb.ml"
  description = "Domain name used to access instance."
}

variable "zone_id" {
  type        = string
  default     = "Z05539563M7J8OK1FQMSA"
  description = "Id of Route53 zone"
}
variable "size" {
  default     = "small"
  description = "Deployment size"
  nullable    = true
  type        = string
}
variable "subdomain" {
  type        = string
  default     = "lsahu"
  description = "Subdomain for accessing the Weights & Biases UI."
}

variable "wandb_license" {
  type = string
  default = "e66eb4aaa3ad8db96aef6477348c09e7cf07cc9c"
}

variable "database_engine_version" {
  description = "Version for MySQL Auora"
  type        = string
  default     = "8.0.mysql_aurora.3.07.1"
}

variable "database_instance_class" {
  description = "Instance type to use by database master instance."
  type        = string
  default     = "db.r5.4xlarge"
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
  default     = "1.32"
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
variable "system_reserved_cpu_millicores" {
  description = "(Optional) The amount of 'system-reserved' CPU millicores to pass to the kubelet. For example: 100.  A value of -1 disables the flag."
  type        = number
  default     = -1
}

variable "system_reserved_memory_megabytes" {
  description = "(Optional) The amount of 'system-reserved' memory in megabytes to pass to the kubelet. For example: 100.  A value of -1 disables the flag."
  type        = number
  default     = -1
}

variable "system_reserved_ephemeral_megabytes" {
  description = "(Optional) The amount of 'system-reserved' ephemeral storage in megabytes to pass to the kubelet. For example: 1000.  A value of -1 disables the flag."
  type        = number
  default     = -1
}

variable "system_reserved_pid" {
  description = "(Optional) The amount of 'system-reserved' process ids [pid] to pass to the kubelet. For example: 1000.  A value of -1 disables the flag."
  type        = number
  default     = -1
}
variable "aws_loadbalancer_controller_tags" {
  description = "(Optional) A map of AWS tags to apply to all resources managed by load balancer and cluster"
  type        = map(string)
  default     = {}
}
variable "vpc_id" {
  type        = string
  default = "vpc-014de03c99e51ac14"
  description = "VPC network ID"
}
variable "vpc_cidr" {
  type        = string  
  default = "10.0.0.0/16"
  description = "VPC network CIDR"
}

variable "network_private_subnets" {
  type        = list(string)
  description = "Subnet IDs"
  default = ["subnet-02ca8cb70a9a05b34", "subnet-0bf844b7dbff15f3f"]
}

variable "network_public_subnets" {
  type        = list(string)
  description = "Subnet IDs"
  default = ["subnet-01610b7cbb35736e6", "subnet-03f83f6eec0f217b7"]
}

variable "network_database_subnets" {
  type        = list(string)
  description = "Subnet IDs"
  default = ["subnet-0d7820bb6da0775c9", "subnet-04eafd7a8bf8e74a1"]
}

variable "network_private_subnet_cidrs" {
  type        = list(string)
  description = "Subnet CIDRs"
  default = ["10.0.128.0/20", "10.0.144.0/20"]
}

variable "network_public_subnet_cidrs" {
  type        = list(string)
  description = "Subnet CIDRs"
  default = ["10.0.0.0/20", "10.0.16.0/20"]
}

variable "network_database_subnet_cidrs" {
  type        = list(string)
  description = "Subnet CIDRs"
  default = ["10.0.32.0/25", "10.0.32.128/25"]
}

variable "network_elasticache_subnets" {
  type        = list(string)
  description = "Subnet CIDRs"
  default = ["subnet-0d7820bb6da0775c9", "subnet-04eafd7a8bf8e74a1"]
}
variable "create_elasticache" {
  type        = bool
  default     = true
  description = "whether to create an elasticache redis"
}
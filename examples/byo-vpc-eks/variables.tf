# =============================================================================
# BASIC CONFIGURATION
# =============================================================================
variable "namespace" {
  type        = string
  description = "Name prefix used for resources"
}

variable "region" {
  type        = string
  description = "Region to deploy resources"
}

# variable "size" {
#   description = "Deployment size"
#   nullable    = true
#   type        = string
#   default     = "small"
# }

# =============================================================================
# DNS AND DOMAIN CONFIGURATION
# =============================================================================
variable "domain_name" {
  type        = string
  description = "Domain name used to access instance."
}

# variable "zone_id" {
#   type        = string
#   description = "Id of Route53 zone"
# }

variable "subdomain" {
  type        = string
  description = "Subdomain for accessing the Weights & Biases UI."
}

# =============================================================================
# WANDB APPLICATION CONFIGURATION
# =============================================================================
variable "wandb_license" {
  type        = string
  description = "WandB license key - should be provided via environment variable TF_VAR_wandb_license"
  sensitive   = true
}

variable "wandb_version" {
  description = "The version of Weights & Biases local to deploy."
  type        = string
}

variable "wandb_image" {
  description = "Docker repository of to pull the wandb image from."
  type        = string
}

variable "other_wandb_env" {
  type        = map(string)
  description = "Extra environment variables for W&B"
  default     = {}
}

# =============================================================================
# HELM OPERATOR CONFIGURATION
# =============================================================================
variable "operator_chart_version" {
  type        = string
  description = "Version of the operator chart to deploy"
  default     = "1.4.2"
}

variable "controller_image_tag" {
  type        = string
  description = "Tag of the controller image to deploy"
  default     = "1.20.0"
}

variable "enable_helm_operator" {
  type        = bool
  default     = true
  description = "Enable or disable applying and releasing W&B Operator chart"
}

variable "enable_helm_wandb" {
  type        = bool
  default     = true
  description = "Enable or disable applying and releasing CR chart"
}

variable "operator_chart_namespace" {
  type        = string
  description = "Namespace to deploy the operator chart"
  default     = "byo-vpc-eks"
}

variable "wandb_chart_namespace" {
  type        = string
  description = "Namespace to deploy the wandb chart"
  default     = "byo-vpc-eks"
}

# =============================================================================
# EKS CLUSTER CONFIGURATION
# =============================================================================
variable "create_eks_cluster" {
  type        = bool
  description = "Whether to create a new EKS cluster or use an existing one. Set to false to use existing cluster."
}

# variable "eks_cluster_version" {
#   description = "EKS cluster kubernetes version"
#   nullable    = false
#   type        = string
# }

# variable "kubernetes_instance_types" {
#   description = "EC2 Instance type for primary node group."
#   type        = list(string)
# }

variable "existing_eks_cluster_name" {
  type        = string
  description = "Name of the existing EKS cluster to use when create_eks_cluster is false"
}

# variable "existing_eks_cluster_endpoint" {
#   type        = string
#   description = "Endpoint of the existing EKS cluster"
# }

# variable "existing_eks_cluster_ca_certificate" {
#   type        = string
#   description = "Certificate authority data for the existing EKS cluster"
# }

# Kubernetes node resource reservations (not used in BYO cluster scenario)
# variable "system_reserved_cpu_millicores" {
#   description = "(Optional) The amount of 'system-reserved' CPU millicores to pass to the kubelet. For example: 100.  A value of -1 disables the flag."
#   type        = number
#   default     = 100
# }
#
# variable "system_reserved_memory_megabytes" {
#   description = "(Optional) The amount of 'system-reserved' memory in megabytes to pass to the kubelet. For example: 100.  A value of -1 disables the flag."
#   type        = number
#   default     = 100
# }
#
# variable "system_reserved_ephemeral_megabytes" {
#   description = "(Optional) The amount of 'system-reserved' ephemeral storage in megabytes to pass to the kubelet. For example: 1000.  A value of -1 disables the flag."
#   type        = number
#   default     = 1000
# }
#
# variable "system_reserved_pid" {
#   description = "(Optional) The amount of 'system-reserved' process ids [pid] to pass to the kubelet. For example: 1000.  A value of -1 disables the flag."
#   type        = number
#   default     = 1000
# }

# =============================================================================
# DATABASE CONFIGURATION
# =============================================================================
variable "create_database" {
  type        = bool
  description = "Whether to create a new RDS database or use an existing one. Set to false to use existing database connection string."
  default     = true
}

variable "database_engine_version" {
  description = "Version for MySQL Auora"
  type        = string
  default     = "8.0.mysql_aurora.3.07.1"
}

variable "database_instance_class" {
  description = "Instance type to use by database master instance."
  type        = string
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

# External database configuration
variable "existing_database_connection_string" {
  type        = string
  description = "Database connection string when using existing EKS cluster"
  sensitive   = true
  default     = ""
}

variable "mysql_host" {
  type        = string
  description = "MySQL host for existing database"
  default     = ""
}

variable "mysql_user" {
  type        = string
  description = "MySQL username for existing database"
  default     = ""
}

variable "mysql_password" {
  type        = string
  description = "MySQL password for existing database"
  sensitive   = true
  default     = ""
}

variable "mysql_database" {
  type        = string
  description = "MySQL database name for existing database"
  default     = ""
}

variable "mysql_port" {
  type        = number
  description = "MySQL port for existing database"
  default     = 3306
}

# =============================================================================
# NETWORK CONFIGURATION
# =============================================================================
variable "vpc_id" {
  type        = string
  description = "VPC network ID"
}

# variable "vpc_cidr" {
#   type        = string
#   description = "VPC network CIDR"
# }

variable "network_private_subnets" {
  type        = list(string)
  description = "Subnet IDs"
}

# variable "network_public_subnets" {
#   type        = list(string)
#   description = "Subnet IDs"
# }

variable "network_database_subnets" {
  type        = list(string)
  description = "Subnet IDs"
}

variable "network_private_subnet_cidrs" {
  type        = list(string)
  description = "Subnet CIDRs"
}

# variable "network_public_subnet_cidrs" {
#   type        = list(string)
#   description = "Subnet CIDRs"
# }

# variable "network_database_subnet_cidrs" {
#   type        = list(string)
#   description = "Subnet CIDRs"
# }

# variable "network_elasticache_subnets" {
#   type        = list(string)
#   description = "Subnet CIDRs"
#   default     = []
# }

# =============================================================================
# SECURITY CONFIGURATION
# =============================================================================
variable "allowed_inbound_cidr" {
  description = "CIDR blocks allowed to access the infrastructure. Restrict to your office/VPN IP ranges."
  type        = list(string)
  nullable    = false
  validation {
    condition     = length(var.allowed_inbound_cidr) > 0
    error_message = "At least one CIDR block must be specified."
  }
}

# variable "allowed_inbound_ipv6_cidr" {
#   description = "IPv6 CIDR blocks allowed to access the infrastructure. Restrict to your office/VPN IPv6 ranges."
#   type        = list(string)
#   default     = ["::/0"]
# }

# =============================================================================
# STORAGE CONFIGURATION
# =============================================================================
variable "bucket_name" {
  type        = string
  description = "S3 bucket name for WandB data storage"
}

variable "bucket_kms_key_arn" {
  type        = string
  description = "The Amazon Resource Name of the KMS key with which S3 storage bucket objects will be encrypted."
}

# variable "bucket_path" {
#   type        = string
#   description = "Path within S3 bucket for WandB data"
#   default     = ""
# }

# =============================================================================
# CACHE CONFIGURATION
# =============================================================================
# variable "create_elasticache" {
#   type        = bool
#   description = "whether to create an elasticache redis"
#   default     = false
# }

# =============================================================================
# LOAD BALANCER CONFIGURATION
# =============================================================================
variable "aws_loadbalancer_controller_tags" {
  description = "(Optional) A map of AWS tags to apply to all resources managed by load balancer and cluster"
  type        = map(string)
}


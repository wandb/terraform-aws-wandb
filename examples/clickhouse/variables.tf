variable "region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-2"
}

variable "namespace" {
  description = "Namespace prefix for resource names"
  type        = string
  default     = "clickhouse"
}

variable "environment" {
  description = "Environment tag for resources"
  type        = string
  default     = "production"
}

variable "eks_cluster_name" {
  description = "Name of the existing EKS cluster where ClickHouse will be deployed"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider for the EKS cluster (for IRSA)"
  type        = string
}

variable "s3_kms_key_arn" {
  description = "ARN of the KMS key used for S3 bucket encryption"
  type        = string
}

variable "create_s3_bucket" {
  description = "Create an S3 bucket for ClickHouse storage"
  type        = bool
  default     = true
}
variable "existing_s3_bucket_name" {
  description = "Name of existing S3 bucket to use (when create_s3_bucket = false)"
  type        = string
  default     = ""
}
variable "clickhouse_namespace" {
  description = "Kubernetes namespace for ClickHouse deployment"
  type        = string
  default     = "clickhouse"
}

variable "clickhouse_cluster_name" {
  description = "Name of the ClickHouse cluster"
  type        = string
  default     = "clickhouse"
}

variable "clickhouse_username" {
  description = "Username for ClickHouse admin user"
  type        = string
  default     = "weave"
}

variable "clickhouse_password" {
  description = "Password for ClickHouse admin user"
  type        = string
  default     = "weave123"
}

variable "clickhouse_version" {
  description = "ClickHouse server version"
  type        = string
  default     = "23.8"
}

variable "altinity_operator_version" {
  description = "Version of Altinity ClickHouse operator"
  type        = string
  default     = "0.25.3"
}

# ClickHouse Cluster Configuration
variable "clickhouse_shards" {
  description = "Number of ClickHouse shards"
  type        = number
  default     = 1
}

variable "clickhouse_replicas" {
  description = "Number of ClickHouse replicas per shard"
  type        = number
  default     = 3
}

# ClickHouse Keeper Configuration
variable "keeper_replicas" {
  description = "Number of ClickHouse Keeper replicas"
  type        = number
  default     = 3
}

variable "keeper_cpu_request" {
  description = "CPU request for ClickHouse Keeper pods"
  type        = string
  default     = "100m"
}

variable "keeper_cpu_limit" {
  description = "CPU limit for ClickHouse Keeper pods"
  type        = string
  default     = "500m"
}

variable "keeper_memory_request" {
  description = "Memory request for ClickHouse Keeper pods"
  type        = string
  default     = "256Mi"
}

variable "keeper_memory_limit" {
  description = "Memory limit for ClickHouse Keeper pods"
  type        = string
  default     = "1Gi"
}

variable "keeper_storage_size" {
  description = "Storage size for ClickHouse Keeper persistent volumes"
  type        = string
  default     = "10Gi"
}

# ClickHouse Server Resource Configuration
variable "clickhouse_cpu_request" {
  description = "CPU request for ClickHouse server pods"
  type        = string
  default     = "4"
}

variable "clickhouse_cpu_limit" {
  description = "CPU limit for ClickHouse server pods"
  type        = string
  default     = "8"
}

variable "clickhouse_memory_request" {
  description = "Memory request for ClickHouse server pods"
  type        = string
  default     = "32Gi"
}

variable "clickhouse_memory_limit" {
  description = "Memory limit for ClickHouse server pods"
  type        = string
  default     = "64Gi"
}

variable "clickhouse_storage_size" {
  description = "Storage size for ClickHouse server persistent volumes"
  type        = string
  default     = "200Gi"
}

variable "storage_class_name" {
  description = "Storage class name for persistent volumes"
  type        = string
  default     = "gp3"
}

# S3 Storage Configuration
variable "enable_s3_storage" {
  description = "Enable S3 storage for ClickHouse data"
  type        = bool
  default     = true
}

# Node Scheduling
variable "node_selector" {
  description = "Node selector for ClickHouse pods"
  type        = map(string)
  default     = {}
}

variable "tolerations" {
  description = "Tolerations for ClickHouse pods"
  type = list(object({
    key      = string
    operator = string
    value    = optional(string)
    effect   = string
  }))
  default = []
}

# External Service Configuration
variable "create_external_service" {
  description = "Create an external service to expose ClickHouse"
  type        = bool
  default     = false
}

variable "external_service_type" {
  description = "Type of external service (LoadBalancer, NodePort, etc.)"
  type        = string
  default     = "LoadBalancer"
}

variable "external_service_annotations" {
  description = "Annotations for the external service"
  type        = map(string)
  default     = {}
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access ClickHouse external service"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

# Weave Configuration


variable "weave_namespace" {
  description = "Kubernetes namespace for Weave deployment"
  type        = string
  default     = "weave"
}

variable "enable_weave_integration" {
  description = "Enable Weave integration with ClickHouse"
  type        = bool
  default     = true
}

# Monitoring and Logging
variable "enable_monitoring" {
  description = "Enable monitoring for ClickHouse"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Enable structured logging for ClickHouse"
  type        = bool
  default     = true
}

# Backup Configuration
variable "enable_backups" {
  description = "Enable automated backups to S3"
  type        = bool
  default     = true
}

variable "backup_schedule" {
  description = "Cron schedule for automated backups"
  type        = string
  default     = "0 2 * * *" # Daily at 2 AM
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
}

# Security Configuration
variable "enable_tls" {
  description = "Enable TLS for ClickHouse connections"
  type        = bool
  default     = true
}

variable "tls_secret_name" {
  description = "Name of Kubernetes secret containing TLS certificates"
  type        = string
  default     = "clickhouse-tls"
}

# Network Security
variable "network_policy_enabled" {
  description = "Enable Kubernetes network policies for ClickHouse"
  type        = bool
  default     = true
}

variable "allowed_namespaces" {
  description = "List of namespaces allowed to access ClickHouse"
  type        = list(string)
  default     = ["weave", "wandb"]
}

# Performance Tuning
variable "max_connections" {
  description = "Maximum number of connections to ClickHouse"
  type        = number
  default     = 4096
}

variable "max_concurrent_queries" {
  description = "Maximum number of concurrent queries"
  type        = number
  default     = 100
}

variable "max_memory_usage" {
  description = "Maximum memory usage per query in bytes"
  type        = string
  default     = "10000000000" # 10GB
}

# Cache Configuration
variable "uncompressed_cache_size" {
  description = "Size of uncompressed cache in bytes"
  type        = string
  default     = "8589934592" # 8GB
}

variable "mark_cache_size" {
  description = "Size of mark cache in bytes"
  type        = string
  default     = "5368709120" # 5GB
}

variable "s3_cache_size" {
  description = "Size of S3 disk cache"
  type        = string
  default     = "10Gi"
}

# AWS Authentication Configuration
variable "use_aws_access_keys" {
  description = "Use AWS access keys for S3 authentication instead of IRSA"
  type        = bool
  default     = false
}

variable "aws_access_key_id" {
  description = "AWS access key ID (required when use_aws_access_keys is true)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS secret access key (required when use_aws_access_keys is true)"
  type        = string
  default     = ""
  sensitive   = true
}

# Additional Tags
variable "additional_tags" {
  description = "Additional tags to apply to AWS resources"
  type        = map(string)
  default     = {}
}
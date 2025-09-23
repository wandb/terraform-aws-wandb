output "clickhouse_cluster_name" {
  description = "Name of the deployed ClickHouse cluster"
  value       = var.clickhouse_cluster_name
}

output "clickhouse_namespace" {
  description = "Kubernetes namespace where ClickHouse is deployed"
  value       = kubernetes_namespace.clickhouse.metadata[0].name
}

output "clickhouse_service_name" {
  description = "Name of the ClickHouse service"
  value       = "clickhouse-${var.clickhouse_cluster_name}"
}

output "clickhouse_http_endpoint" {
  description = "HTTP endpoint for ClickHouse connections"
  value       = "http://clickhouse-${var.clickhouse_cluster_name}.${kubernetes_namespace.clickhouse.metadata[0].name}.svc.cluster.local:8123"
}

output "clickhouse_native_endpoint" {
  description = "Native endpoint for ClickHouse connections"
  value       = "clickhouse-${var.clickhouse_cluster_name}.${kubernetes_namespace.clickhouse.metadata[0].name}.svc.cluster.local:9000"
}

output "clickhouse_username" {
  description = "Username for ClickHouse authentication"
  value       = var.clickhouse_username
}

output "clickhouse_password" {
  description = "Password for ClickHouse authentication"
  value       = random_password.clickhouse_password.result
  sensitive   = true
}

output "clickhouse_password_secret_name" {
  description = "Name of Kubernetes secret containing ClickHouse credentials"
  value       = kubernetes_secret.clickhouse_credentials.metadata[0].name
}

output "s3_bucket_name" {
  description = "Name of S3 bucket used for ClickHouse storage"
  value       = local.s3_bucket_name
}

output "s3_bucket_arn" {
  description = "ARN of S3 bucket used for ClickHouse storage"
  value       = local.s3_bucket_arn
}

output "iam_role_arn" {
  description = "ARN of IAM role for ClickHouse S3 access"
  value       = aws_iam_role.clickhouse_s3_role.arn
}

output "service_account_name" {
  description = "Name of Kubernetes service account for ClickHouse"
  value       = kubernetes_service_account.clickhouse.metadata[0].name
}

output "keeper_service_name" {
  description = "Name of ClickHouse Keeper service"
  value       = "clickhouse-keeper"
}

output "keeper_endpoint" {
  description = "Endpoint for ClickHouse Keeper service"
  value       = "clickhouse-keeper.${kubernetes_namespace.clickhouse.metadata[0].name}.svc.cluster.local:2181"
}

output "external_service_name" {
  description = "Name of external ClickHouse service (if created)"
  value       = var.create_external_service ? kubernetes_service.clickhouse_external[0].metadata[0].name : null
}

output "external_service_endpoint" {
  description = "External endpoint for ClickHouse (if LoadBalancer service created)"
  value = var.create_external_service && var.external_service_type == "LoadBalancer" ? (
    length(kubernetes_service.clickhouse_external[0].status[0].load_balancer[0].ingress) > 0 ?
    kubernetes_service.clickhouse_external[0].status[0].load_balancer[0].ingress[0].hostname != null ?
    kubernetes_service.clickhouse_external[0].status[0].load_balancer[0].ingress[0].hostname :
    kubernetes_service.clickhouse_external[0].status[0].load_balancer[0].ingress[0].ip : null
  ) : null
}

output "clickhouse_replicas" {
  description = "Number of ClickHouse replicas deployed"
  value       = var.clickhouse_replicas
}

output "clickhouse_shards" {
  description = "Number of ClickHouse shards deployed"
  value       = var.clickhouse_shards
}

output "keeper_replicas" {
  description = "Number of ClickHouse Keeper replicas deployed"
  value       = var.keeper_replicas
}

output "storage_class" {
  description = "Storage class used for persistent volumes"
  value       = var.storage_class_name
}

output "clickhouse_storage_size" {
  description = "Size of storage allocated per ClickHouse pod"
  value       = var.clickhouse_storage_size
}

output "keeper_storage_size" {
  description = "Size of storage allocated per Keeper pod"
  value       = var.keeper_storage_size
}

# Connection Information for Applications
output "connection_info" {
  description = "Connection information for applications"
  value = {
    cluster_name    = var.clickhouse_cluster_name
    namespace       = kubernetes_namespace.clickhouse.metadata[0].name
    http_port       = 8123
    native_port     = 9000
    username        = var.clickhouse_username
    password_secret = kubernetes_secret.clickhouse_credentials.metadata[0].name
    internal_host   = "clickhouse-${var.clickhouse_cluster_name}.${kubernetes_namespace.clickhouse.metadata[0].name}.svc.cluster.local"
    keeper_host     = "clickhouse-keeper.${kubernetes_namespace.clickhouse.metadata[0].name}.svc.cluster.local"
    keeper_port     = 2181
    s3_bucket       = local.s3_bucket_name
    s3_region       = var.region
  }
}

# Weave Integration Information
output "weave_integration_config" {
  description = "Configuration for Weave integration with ClickHouse"
  value = var.enable_weave_integration ? {
    clickhouse_host      = "clickhouse-${var.clickhouse_cluster_name}.${kubernetes_namespace.clickhouse.metadata[0].name}.svc.cluster.local"
    clickhouse_port      = 9000
    clickhouse_http_port = 8123
    clickhouse_user      = var.clickhouse_username
    clickhouse_database  = "default"
    clickhouse_cluster   = var.clickhouse_cluster_name
    replicated_mode      = var.clickhouse_replicas > 1
    environment_vars = {
      WF_CLICKHOUSE_HOST         = "clickhouse-${var.clickhouse_cluster_name}.${kubernetes_namespace.clickhouse.metadata[0].name}.svc.cluster.local"
      WF_CLICKHOUSE_PORT         = "9000"
      WF_CLICKHOUSE_USER         = var.clickhouse_username
      WF_CLICKHOUSE_PASSWORD_REF = "secret:${kubernetes_secret.clickhouse_credentials.metadata[0].name}:password"
      WF_CLICKHOUSE_DATABASE     = "default"
      WF_CLICKHOUSE_REPLICATED   = var.clickhouse_replicas > 1 ? "true" : "false"
      WF_CLICKHOUSE_CLUSTER      = var.clickhouse_cluster_name
    }
  } : null
}

# Monitoring Endpoints
output "monitoring_endpoints" {
  description = "Monitoring endpoints for ClickHouse"
  value = {
    clickhouse_metrics = "http://clickhouse-${var.clickhouse_cluster_name}.${kubernetes_namespace.clickhouse.metadata[0].name}.svc.cluster.local:8123/metrics"
    clickhouse_ping    = "http://clickhouse-${var.clickhouse_cluster_name}.${kubernetes_namespace.clickhouse.metadata[0].name}.svc.cluster.local:8123/ping"
    system_tables      = "http://clickhouse-${var.clickhouse_cluster_name}.${kubernetes_namespace.clickhouse.metadata[0].name}.svc.cluster.local:8123/?query=SELECT * FROM system.clusters"
  }
}

# Security Information
output "security_info" {
  description = "Security configuration information"
  value = {
    tls_enabled            = var.enable_tls
    network_policy_enabled = var.network_policy_enabled
    allowed_namespaces     = var.allowed_namespaces
    s3_encryption          = "AES256"
    kms_key_arn            = var.s3_kms_key_arn
  }
}
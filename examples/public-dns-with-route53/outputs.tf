# =============================================================================
# DNS and Access Outputs
# =============================================================================

output "url" {
  description = "The URL to access your W&B instance"
  value       = module.wandb_infra.url
}

output "route53_zone_id" {
  description = "The Route53 hosted zone ID created for W&B"
  value       = aws_route53_zone.public.zone_id
}

output "route53_nameservers" {
  description = "Route53 nameservers for the hosted zone. Update your domain registrar to use these nameservers."
  value       = aws_route53_zone.public.name_servers
}

output "route53_record_fqdn" {
  description = "The FQDN of the Route53 DNS record created for W&B"
  value       = aws_route53_record.wandb.fqdn
}

output "alb_hostname" {
  description = "The ALB hostname that the DNS record points to"
  value       = data.kubernetes_ingress_v1.wandb.status[0].load_balancer[0].ingress[0].hostname
}

output "domain" {
  description = "The domain name configured for W&B"
  value       = var.domain
}

output "subdomain" {
  description = "The subdomain configured for W&B (if any)"
  value       = var.subdomain
}

# =============================================================================
# EKS Cluster Outputs
# =============================================================================

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.wandb_infra.cluster_name
}

output "cluster_version" {
  description = "The Kubernetes version of the EKS cluster"
  value       = var.eks_cluster_version
}

output "eks_node_instance_type" {
  description = "The EC2 instance type used for EKS worker nodes"
  value       = module.wandb_infra.eks_node_instance_type
}

# =============================================================================
# Storage Outputs
# =============================================================================

output "bucket_name" {
  description = "The name of the S3 bucket for W&B file storage"
  value       = module.wandb_infra.bucket_name
}

output "bucket_region" {
  description = "The AWS region of the S3 bucket"
  value       = module.wandb_infra.bucket_region
}

output "bucket_queue_name" {
  description = "The name of the SQS queue for S3 event notifications"
  value       = module.wandb_infra.bucket_queue_name
}

# =============================================================================
# Database Outputs
# =============================================================================

output "database_instance_type" {
  description = "The instance type of the RDS database"
  value       = module.wandb_infra.database_instance_type
}

# =============================================================================
# Security Outputs
# =============================================================================

output "kms_key_arn" {
  description = "The ARN of the KMS key used for encryption"
  value       = module.wandb_infra.kms_key_arn
}

# =============================================================================
# Network Outputs
# =============================================================================

output "vpc_id" {
  description = "The ID of the VPC created for W&B"
  value       = module.wandb_infra.network_id
}

# =============================================================================
# Redis Outputs
# =============================================================================

output "redis_connection_string" {
  description = "The connection string for the ElastiCache Redis cluster (if created)"
  value       = try(module.wandb_infra.elasticache_connection_string, "Not created")
  sensitive   = true
}

output "redis_instance_type" {
  description = "The instance type of the Redis cluster (if created)"
  value       = try(module.wandb_infra.redis_instance_type, "Not created")
}

# =============================================================================
# Deployment Information
# =============================================================================

output "deployment_info" {
  description = "Summary of the W&B deployment"
  value = {
    url            = module.wandb_infra.url
    region         = var.aws_region
    namespace      = var.namespace
    eks_cluster    = module.wandb_infra.cluster_name
    public_access  = true
    dns_managed_by = "Route53 (AWS)"
    nameservers    = aws_route53_zone.public.name_servers
  }
}

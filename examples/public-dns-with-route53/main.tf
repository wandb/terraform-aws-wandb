# =============================================================================
# AWS Provider Configuration
# =============================================================================
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      GithubRepo  = "terraform-aws-wandb"
      GithubOrg   = "wandb"
      Environment = "Example"
      Example     = "PublicDnsOnRoute53"
      ManagedBy   = "Terraform"
    }
  }
}

# =============================================================================
# Route53 DNS Zone - Creates a NEW hosted zone for W&B deployment
# =============================================================================
# This creates a new Route53 hosted zone for the specified domain.
# After creation, you'll need to update your domain registrar's nameservers
# to point to the Route53 nameservers for this zone.
resource "aws_route53_zone" "public" {
  name = var.domain

  tags = {
    Name    = "${var.namespace}-wandb-zone"
    Purpose = "WandB DNS Management"
  }
}

# =============================================================================
# W&B Infrastructure Module - Creates all AWS resources
# =============================================================================
# This module creates:
# - VPC with public/private subnets
# - EKS cluster with managed node groups
# - RDS Aurora MySQL database
# - ElastiCache Redis
# - S3 bucket for artifacts
# - SQS queue for S3 notifications
# - KMS keys for encryption
# - ACM certificate for SSL/TLS
# - Application Load Balancer
# - IAM roles and policies
module "wandb_infra" {
  source = "../../"

  namespace     = var.namespace
  public_access = true

  # DNS Configuration
  domain_name  = var.domain
  zone_id      = aws_route53_zone.public.zone_id
  subdomain    = var.subdomain
  external_dns = true

  # Network Access Control
  allowed_inbound_cidr      = var.allowed_inbound_cidr
  allowed_inbound_ipv6_cidr = var.allowed_inbound_ipv6_cidr

  # EKS Configuration
  eks_cluster_version            = var.eks_cluster_version
  eks_addon_kube_proxy_version   = var.eks_addon_kube_proxy_version
  kubernetes_public_access       = true
  kubernetes_public_access_cidrs = var.allowed_inbound_cidr

  # W&B License
  license = var.license
}

# =============================================================================
# EKS Cluster Data Sources - Required for Kubernetes provider
# =============================================================================
data "aws_eks_cluster" "app_cluster" {
  name = module.wandb_infra.cluster_name
}

data "aws_eks_cluster_auth" "app_cluster" {
  name = module.wandb_infra.cluster_name
}

# =============================================================================
# Kubernetes Provider Configuration
# =============================================================================
# Configures Kubernetes provider to interact with the EKS cluster
provider "kubernetes" {
  host                   = data.aws_eks_cluster.app_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.app_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.app_cluster.token
}

# =============================================================================
# Helm Provider Configuration
# =============================================================================
# Configures Helm provider to deploy charts to the EKS cluster
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.app_cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.app_cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.app_cluster.token
  }
}

# =============================================================================
# W&B Application Deployment - Deploys W&B to Kubernetes
# =============================================================================
# This module deploys the W&B application to the EKS cluster using Helm.
# It configures the application to use the infrastructure resources created above:
# - S3 bucket for file storage
# - SQS queue for async processing
# - MySQL database for metadata
# - Redis for caching (if enabled)
# - KMS keys for encryption
#
# Note: Using latest version from main branch. For production, pin to a specific release:
# source = "github.com/wandb/terraform-kubernetes-wandb?ref=v1.x.x"
module "wandb_app" {
  source = "github.com/wandb/terraform-kubernetes-wandb"

  # W&B License Key
  license = var.license

  # Application URL (with subdomain if specified)
  host = module.wandb_infra.url

  # S3 Configuration
  bucket             = "s3://${module.wandb_infra.bucket_name}"
  bucket_aws_region  = module.wandb_infra.bucket_region
  bucket_queue       = "sqs://${module.wandb_infra.bucket_queue_name}"
  bucket_kms_key_arn = module.wandb_infra.kms_key_arn

  # Database Configuration
  database_connection_string = "mysql://${module.wandb_infra.database_connection_string}"

  # Ensure infrastructure is ready before deploying the application
  depends_on = [module.wandb_infra]
}

# =============================================================================
# Route53 DNS Record - Creates A record pointing to ALB
# =============================================================================
# Get the ALB DNS name from the Kubernetes ingress
data "kubernetes_ingress_v1" "wandb" {
  metadata {
    name      = "wandb"
    namespace = "default"
  }

  depends_on = [module.wandb_app]
}

# Get ALB hosted zone ID for the current AWS region
data "aws_elb_hosted_zone_id" "main" {}

# Create the Route53 A record (alias) pointing to the ALB
resource "aws_route53_record" "wandb" {
  zone_id = aws_route53_zone.public.zone_id
  name    = var.subdomain == null ? var.domain : "${var.subdomain}.${var.domain}"
  type    = "A"

  alias {
    name                   = data.kubernetes_ingress_v1.wandb.status[0].load_balancer[0].ingress[0].hostname
    zone_id                = data.aws_elb_hosted_zone_id.main.id
    evaluate_target_health = true
  }
}
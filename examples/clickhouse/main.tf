terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.6"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      GithubRepo  = "terraform-aws-wandb"
      GithubOrg   = "wandb"
      Environment = var.environment
      Component   = "ClickHouse"
    }
  }
}

# Data source for existing EKS cluster
data "aws_eks_cluster" "app_cluster" {
  name = var.eks_cluster_name
}

data "aws_eks_cluster_auth" "app_cluster" {
  name = var.eks_cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.app_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.app_cluster.certificate_authority[0].data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.app_cluster.name]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.app_cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.app_cluster.certificate_authority[0].data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.app_cluster.name]
      command     = "aws"
    }
  }
}

provider "kubectl" {
  host                   = data.aws_eks_cluster.app_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.app_cluster.certificate_authority[0].data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.app_cluster.name]
    command     = "aws"
  }
}

# Create S3 bucket for ClickHouse storage (conditional)
resource "aws_s3_bucket" "clickhouse_storage" {
  count  = var.create_s3_bucket ? 1 : 0
  bucket = "${var.namespace}-clickhouse-storage"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "clickhouse_storage" {
  count  = var.create_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.clickhouse_storage[0].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.s3_kms_key_arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "clickhouse_storage" {
  count  = var.create_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.clickhouse_storage[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "clickhouse_storage" {
  count  = var.create_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.clickhouse_storage[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Data source for existing S3 bucket (when not creating new one)
data "aws_s3_bucket" "existing_clickhouse_storage" {
  count  = var.create_s3_bucket ? 0 : 1
  bucket = var.existing_s3_bucket_name
}

# Local variables for S3 bucket
locals {
  s3_bucket_name = var.create_s3_bucket ? aws_s3_bucket.clickhouse_storage[0].bucket : data.aws_s3_bucket.existing_clickhouse_storage[0].bucket
  s3_bucket_arn  = var.create_s3_bucket ? aws_s3_bucket.clickhouse_storage[0].arn : data.aws_s3_bucket.existing_clickhouse_storage[0].arn
}

# IAM role for ClickHouse pods to access S3
resource "aws_iam_role" "clickhouse_s3_role" {
  name = "${var.namespace}-clickhouse-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${replace(var.oidc_provider_arn, "/^.*oidc-provider//", "")}:sub" = "system:serviceaccount:${var.clickhouse_namespace}:clickhouse-sa"
            "${replace(var.oidc_provider_arn, "/^.*oidc-provider//", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "clickhouse_s3_policy" {
  name        = "${var.namespace}-clickhouse-s3-policy"
  description = "IAM policy for ClickHouse S3 access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          local.s3_bucket_arn,
          "${local.s3_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = [var.s3_kms_key_arn]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "clickhouse_s3_policy_attachment" {
  role       = aws_iam_role.clickhouse_s3_role.name
  policy_arn = aws_iam_policy.clickhouse_s3_policy.arn
}

# Create namespace for ClickHouse
resource "kubernetes_namespace" "clickhouse" {
  metadata {
    name = var.clickhouse_namespace
    labels = {
      name = var.clickhouse_namespace
    }
  }
}

# Service account with IAM role annotation
resource "kubernetes_service_account" "clickhouse" {
  metadata {
    name      = "clickhouse-sa"
    namespace = kubernetes_namespace.clickhouse.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.clickhouse_s3_role.arn
    }
  }
}

# Generate random password for ClickHouse
resource "random_password" "clickhouse_password" {
  length  = 32
  special = true
}

# Store ClickHouse password in Kubernetes secret
resource "kubernetes_secret" "clickhouse_credentials" {
  metadata {
    name      = "clickhouse-credentials"
    namespace = kubernetes_namespace.clickhouse.metadata[0].name
  }

  data = {
    username = var.clickhouse_username
    password = random_password.clickhouse_password.result
  }

  type = "Opaque"
}

# Store AWS credentials in Kubernetes secret (conditional)
resource "kubernetes_secret" "ch_bucket_credentials" {
  count = var.use_aws_access_keys ? 1 : 0

  metadata {
    name      = "ch-bucket-cred"
    namespace = kubernetes_namespace.clickhouse.metadata[0].name
  }

  data = {
    access_key = var.aws_access_key_id
    secret_key = var.aws_secret_access_key
  }

  type = "Opaque"
}

# Install Altinity ClickHouse Operator using Helm
resource "helm_release" "altinity_operator" {
  name             = "altinity-clickhouse-operator"
  repository       = "https://docs.altinity.com/clickhouse-operator"
  chart            = "altinity-clickhouse-operator"
  namespace        = kubernetes_namespace.clickhouse.metadata[0].name
  create_namespace = false
  version          = var.altinity_operator_version

  set {
    name  = "operator.image.repository"
    value = "altinity/clickhouse-operator"
  }

  set {
    name  = "operator.image.tag"
    value = var.altinity_operator_version
  }
}

# Apply ClickHouse Keeper YAML file
resource "kubectl_manifest" "clickhouse_keeper" {
  depends_on = [helm_release.altinity_operator]
  yaml_body = templatefile("${path.module}/ch-keeper.yaml", {
    namespace         = kubernetes_namespace.clickhouse.metadata[0].name
    storage_class     = var.storage_class_name
    keeper_storage    = var.keeper_storage_size
  })
}

# Apply ClickHouse server YAML file
resource "kubectl_manifest" "clickhouse_server" {
  depends_on = [
    helm_release.altinity_operator,
    kubectl_manifest.clickhouse_keeper,
    kubernetes_secret.clickhouse_credentials,
    kubernetes_secret.ch_bucket_credentials
  ]
  yaml_body = templatefile("${path.module}/ch-server.yaml", {
    namespace           = kubernetes_namespace.clickhouse.metadata[0].name
    storage_class       = var.storage_class_name
    clickhouse_storage  = var.clickhouse_storage_size
    clickhouse_password = var.clickhouse_password
    service_account     = kubernetes_service_account.clickhouse.metadata[0].name
    iam_role_arn        = aws_iam_role.clickhouse_s3_role.arn
    use_aws_access_keys = var.use_aws_access_keys
  })
}

# Service to expose ClickHouse externally (optional)
resource "kubernetes_service" "clickhouse_external" {
  count = var.create_external_service ? 1 : 0

  metadata {
    name        = "clickhouse-external"
    namespace   = kubernetes_namespace.clickhouse.metadata[0].name
    annotations = var.external_service_annotations
  }

  spec {
    selector = {
      "clickhouse.altinity.com/app" = "chop"
    }

    port {
      name        = "http"
      port        = 8123
      target_port = 8123
      protocol    = "TCP"
    }

    port {
      name        = "native"
      port        = 9000
      target_port = 9000
      protocol    = "TCP"
    }

    type                        = var.external_service_type
    load_balancer_source_ranges = var.allowed_cidr_blocks
  }
}
data "aws_caller_identity" "current" {}

locals {
  mysql_port         = 3306
  redis_port         = 6379
  encrypt_ebs_volume = true
}


resource "aws_eks_addon" "eks" {
  cluster_name = var.namespace
  addon_name   = "aws-ebs-csi-driver"
  depends_on = [
    module.eks
  ]
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = var.namespace
  addon_name   = "vpc-cni"
  depends_on   = [module.eks]
}

locals {
  managed_policy_arns = concat([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  ], var.eks_policy_arns)
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 17.23"

  cluster_name    = var.namespace
  cluster_version = var.cluster_version

  vpc_id  = var.network_id
  subnets = var.network_private_subnets

  map_accounts = var.map_accounts
  map_roles    = var.map_roles
  map_users    = var.map_users

  cluster_enabled_log_types            = ["api", "audit", "controllerManager", "scheduler"]
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  cluster_log_retention_in_days        = 30

  cluster_encryption_config = var.kms_key_arn != "" ? [
    {
      provider_key_arn = var.kms_key_arn
      resources        = ["secrets"]
    }
  ] : null

  worker_additional_security_group_ids = [aws_security_group.primary_workers.id]

  node_groups = {
    primary = {
      version                = var.cluster_version,
      desired_capacity       = 2,
      max_capacity           = 5,
      min_capacity           = 2,
      instance_types         = var.instance_types,
      iam_role_arn           = aws_iam_role.node.arn,
      create_launch_template = local.encrypt_ebs_volume,
      disk_encrypted         = local.encrypt_ebs_volume,
      disk_kms_key_id        = var.kms_key_arn,
      force_update_version   = local.encrypt_ebs_volume,
      # IMDsv2
      metadata_http_tokens                 = "required",
      metadata_http_put_response_hop_limit = 2
    }
  }

  tags = {
    GithubRepo         = "wandb"
    GithubOrg          = "terraform-aws-wandb"
    TerraformNamespace = var.namespace
    TerraformModule    = "terraform-aws-wandb/module/app_eks"
  }
}

resource "aws_security_group" "primary_workers" {
  name        = "${var.namespace}-primary-workers"
  description = "EKS primary workers security group."
  vpc_id      = var.network_id
}

resource "aws_security_group_rule" "lb" {
  description              = "Allow container NodePort service to receive load balancer traffic."
  protocol                 = "tcp"
  security_group_id        = aws_security_group.primary_workers.id
  source_security_group_id = var.lb_security_group_inbound_id
  from_port                = var.service_port
  to_port                  = var.service_port
  type                     = "ingress"
}

resource "aws_security_group_rule" "database" {
  description              = "Allow inbound traffic from EKS workers to database"
  protocol                 = "tcp"
  security_group_id        = var.database_security_group_id
  source_security_group_id = aws_security_group.primary_workers.id
  from_port                = local.mysql_port
  to_port                  = local.mysql_port
  type                     = "ingress"
}

resource "aws_security_group_rule" "elasticache" {
  count                    = var.create_elasticache_security_group ? 1 : 0
  description              = "Allow inbound traffic from EKS workers to elasticache"
  protocol                 = "tcp"
  security_group_id        = var.elasticache_security_group_id
  source_security_group_id = aws_security_group.primary_workers.id
  from_port                = local.redis_port
  to_port                  = local.redis_port
  type                     = "ingress"
}

module "lb_controller" {
  source = "./lb_controller"

  namespace   = "namespace"
  oidc_issuer = module.eks.cluster_oidc_issuer_url

  depends_on = [module.eks]
}

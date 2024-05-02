data "aws_caller_identity" "current" {}

locals {
  mysql_port         = 3306
  redis_port         = 6379
  encrypt_ebs_volume = true
  system_reserved = join(",", flatten([
    var.system_reserved_cpu_millicores >= 0 ? ["cpu=${var.system_reserved_cpu_millicores}m"] : [],
    var.system_reserved_memory_megabytes >= 0 ? ["memory=${var.system_reserved_memory_megabytes}Mi"] : [],
    var.system_reserved_ephemeral_megabytes >= 0 ? ["ephemeral-storage=${var.system_reserved_ephemeral_megabytes}Mi"] : [],
    var.system_reserved_pid >= 0 ? ["pid=${var.system_reserved_pid}"] : []
  ]))
  create_launch_template = (local.encrypt_ebs_volume || local.system_reserved != "")
}


resource "aws_eks_addon" "eks" {
  cluster_name = var.namespace
  addon_name   = "aws-ebs-csi-driver"
  depends_on = [
    module.eks
  ]
}

resource "aws_eks_addon" "efs" {
  cluster_name      = module.eks.cluster_id
  addon_name        = "aws-efs-csi-driver"
  addon_version     = "v1.7.1-eksbuild.1" # Ensure this version is compatible
  resolve_conflicts = "OVERWRITE"
  depends_on = [
    module.eks
  ]
}

# removed due to conflict with 
# AWS Load Balancer Controller
# being installed with Helm.
# See: https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.6/
#resource "aws_eks_addon" "vpc_cni" {
#  cluster_name = var.namespace
#  addon_name   = "vpc-cni"
#  depends_on   = [module.eks]
#}

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
      create_launch_template               = local.create_launch_template,
      desired_capacity                     = var.desired_capacity,
      disk_encrypted                       = local.encrypt_ebs_volume,
      disk_kms_key_id                      = var.kms_key_arn,
      disk_type                            = "gp3"
      enable_monitoring                    = true
      force_update_version                 = local.encrypt_ebs_volume,
      iam_role_arn                         = aws_iam_role.node.arn,
      instance_types                       = var.instance_types,
      kubelet_extra_args                   = local.system_reserved != "" ? "--system-reserved=${local.system_reserved}" : "",
      max_capacity                         = 5,
      metadata_http_put_response_hop_limit = 2
      metadata_http_tokens                 = "required",
      min_capacity                         = var.desired_capacity,
      version                              = var.cluster_version,
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

data "tls_certificate" "eks" {
  url = module.eks.cluster_oidc_issuer_url
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = module.eks.cluster_oidc_issuer_url
}

module "lb_controller" {
  source = "./lb_controller"

  namespace                        = var.namespace
  oidc_provider                    = aws_iam_openid_connect_provider.eks
  aws_loadbalancer_controller_tags = var.aws_loadbalancer_controller_tags

  depends_on = [module.eks]
}

module "external_dns" {
  source = "./external_dns"

  namespace     = var.namespace
  oidc_provider = aws_iam_openid_connect_provider.eks
  fqdn          = var.fqdn

  depends_on = [module.eks]
}

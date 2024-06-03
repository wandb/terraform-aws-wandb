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


module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.12"

  prefix_separator                   = ""
  iam_role_name                      = var.namespace
  cluster_security_group_name        = var.namespace
  cluster_security_group_description = "EKS cluster security group."
  cluster_name    = var.namespace
  cluster_version = var.cluster_version

  vpc_id  = var.network_id
  subnet_ids = var.network_private_subnets

  enable_irsa = false
  # aws_auth_accounts = var.map_accounts
  # aws_auth_roles    = var.map_roles
  # aws_auth_users    = var.map_users

  cluster_enabled_log_types            = ["api", "audit", "controllerManager", "scheduler"]
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  cloudwatch_log_group_retention_in_days        = 30

  create_kms_key = false
  cluster_encryption_config = var.kms_key_arn != "" ? {
      provider_key_arn = var.kms_key_arn
      resources        = ["secrets"]
    } : null

  eks_managed_node_group_defaults = {
    vpc_security_group_ids = [aws_security_group.primary_workers.id]
  }

  eks_managed_node_groups = {
    primary = {
      create_launch_template = local.create_launch_template,
      desired_size           = var.desired_capacity,
      min_size               = var.desired_capacity,
      max_size               = 5,
      enable_monitoring                    = true
      force_update_version                 = local.encrypt_ebs_volume,
      iam_role_arn                         = aws_iam_role.node.arn,
      instance_types                       = var.instance_types,
      network_interfaces = [
        {
          device_index = 0
          associate_public_ip_address = false
          delete_on_termination = true
          security_groups = [aws_security_group.primary_workers.id]
        }
       ]
      
      bootstrap_extra_args = local.system_reserved != "" ? "--kubelet-extra-args '--system-reserved=${local.system_reserved}'" : "",
      metadata_http_put_response_hop_limit = 2
      metadata_http_tokens                 = "required",
      cluster_version                      = var.cluster_version,
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            delete_on_termination = true
            volume_type           = "gp3"
            volume_size           = 100
            encrypted             = local.encrypt_ebs_volume
            kms_key_id            = var.kms_key_arn
          }
        }
      }
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

provider "aws" {
  region = "us-east-1"


  default_tags {
    tags = {
      GithubRepo = "terraform-aws-wandb"
      GithubOrg  = "wandb"
      Enviroment = "Example"
      Example    = "BYO-VPC-SQL"
    }
  }
}
data "aws_s3_bucket" "file_storage" {
  depends_on = [module.file_storage]
  bucket     = var.bucket_name
}

data "aws_sqs_queue" "file_storage" {
  count      = local.use_internal_queue ? 0 : 1
  depends_on = [module.file_storage]
  name       = local.bucket_queue_name
}

data "aws_eks_cluster" "app_cluster" {
  name = module.app_eks.cluster_name
}

data "aws_eks_cluster_auth" "app_cluster" {
  name = module.app_eks.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.app_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.app_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.app_cluster.token
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
    token                  = data.aws_eks_cluster_auth.app_cluster.token
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.app_cluster.name]
      command     = "aws"
    }
  }
}

module "kms" {
  source = "../../modules/kms"

  key_alias           = var.kms_key_alias == null ? "${var.namespace}-kms-alias" : var.kms_key_alias
  key_deletion_window = var.kms_key_deletion_window

  key_policy = var.kms_key_policy
}

locals {
  kms_key_arn         = module.kms.key.arn
  use_external_bucket = var.bucket_name != ""
  use_internal_queue  = local.use_external_bucket || var.use_internal_queue
  deployment_size = {
    small = {
      db            = "db.r6g.large",
      node_count    = 3,
      node_instance = "r6i.xlarge"
      cache         = "cache.m6g.large"
    },
    medium = {
      db            = "db.r6g.xlarge",
      node_count    = 3,
      node_instance = "r6i.xlarge"
      cache         = "cache.m6g.large"
    },
    large = {
      db            = "db.r6g.2xlarge",
      node_count    = 3,
      node_instance = "r6i.2xlarge"
      cache         = "cache.m6g.xlarge"
    },
    xlarge = {
      db            = "db.r6g.4xlarge",
      node_count    = 3,
      node_instance = "r6i.2xlarge"
      cache         = "cache.m6g.xlarge"
    },
    xxlarge = {
      db            = "db.r6g.8xlarge",
      node_count    = 3,
      node_instance = "r6i.4xlarge"
      cache         = "cache.m6g.2xlarge"
    }
  }
}

module "file_storage" {
  source = "../../modules/file_storage"

  create_queue        = !local.use_internal_queue
  deletion_protection = var.deletion_protection
  kms_key_arn         = local.kms_key_arn
  namespace           = var.namespace
  sse_algorithm       = "aws:kms"
}

locals {
  bucket_queue_name = local.use_internal_queue ? null : module.file_storage.0.bucket_queue_name
}

locals {
  network_id                   = var.network_id
  network_public_subnets       = var.network_public_subnets
  network_private_subnets      = var.network_private_subnets
  network_private_subnet_cidrs = var.network_private_subnet_cidrs
}

locals {
  create_certificate = var.public_access && var.acm_certificate_arn == null

  fqdn = var.subdomain == null ? var.domain_name : "${var.subdomain}.${var.domain_name}"
}

# Create SSL Ceritifcation if applicable
module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 3.0"

  create_certificate = local.create_certificate

  subject_alternative_names = var.extra_fqdn

  domain_name = var.external_dns ? local.fqdn : var.domain_name
  zone_id     = var.zone_id

  wait_for_validation = true
}

locals {
  acm_certificate_arn = local.create_certificate ? module.acm.acm_certificate_arn : var.acm_certificate_arn
  url                 = local.acm_certificate_arn == null ? "http://${local.fqdn}" : "https://${local.fqdn}"
  domain_filter       = var.custom_domain_filter == null || var.custom_domain_filter == "" ? local.fqdn : var.custom_domain_filter

  internal_app_port = 32543
}

module "app_eks" {
  source = "../../modules/app_eks"

  fqdn = local.domain_filter

  namespace   = var.namespace
  kms_key_arn = local.kms_key_arn

  instance_types = try([local.deployment_size[var.size].node_instance], var.kubernetes_instance_types)
  map_accounts   = var.kubernetes_map_accounts
  map_roles      = var.kubernetes_map_roles
  map_users      = var.kubernetes_map_users

  bucket_kms_key_arns  = local.use_external_bucket ? var.bucket_kms_key_arn : local.kms_key_arn
  bucket_arn           = var.bucket_name == "" ? module.file_storage.bucket_arn : data.aws_s3_bucket.file_storage.arn
  bucket_sqs_queue_arn = local.use_internal_queue ? null : data.aws_sqs_queue.file_storage.0.arn

  network_id              = local.network_id
  network_private_subnets = local.network_private_subnets

  lb_security_group_inbound_id = module.app_lb.security_group_inbound_id
  database_security_group_id   = var.database_security_group_id

  create_elasticache_security_group = var.create_elasticache
  elasticache_security_group_id     = var.create_elasticache ? module.redis.0.security_group_id : null

  cluster_version                      = var.eks_cluster_version
  cluster_endpoint_public_access       = var.kubernetes_public_access
  cluster_endpoint_public_access_cidrs = var.kubernetes_public_access_cidrs

  eks_policy_arns = var.eks_policy_arns

  system_reserved_cpu_millicores      = var.system_reserved_cpu_millicores
  system_reserved_memory_megabytes    = var.system_reserved_memory_megabytes
  system_reserved_ephemeral_megabytes = var.system_reserved_ephemeral_megabytes
  system_reserved_pid                 = var.system_reserved_pid

  aws_loadbalancer_controller_tags = var.aws_loadbalancer_controller_tags

  eks_addon_efs_csi_driver_version = var.eks_addon_efs_csi_driver_version
  eks_addon_ebs_csi_driver_version = var.eks_addon_ebs_csi_driver_version
  eks_addon_coredns_version        = var.eks_addon_coredns_version
  eks_addon_kube_proxy_version     = var.eks_addon_kube_proxy_version
  eks_addon_vpc_cni_version        = var.eks_addon_vpc_cni_version
  eks_addon_metrics_server_version = var.eks_addon_metrics_server_version
}

locals {
  full_fqdn  = var.enable_dummy_dns ? "old.${local.fqdn}" : local.fqdn
  extra_fqdn = var.enable_dummy_dns ? [for fqdn in var.extra_fqdn : "old.${fqdn}"] : var.extra_fqdn
}

module "app_lb" {
  source = "../../modules/app_lb"

  namespace                 = var.namespace
  allowed_inbound_cidr      = var.allowed_inbound_cidr
  allowed_inbound_ipv6_cidr = var.allowed_inbound_ipv6_cidr

  private_endpoint_cidr       = var.allowed_private_endpoint_cidr
  enable_private_only_traffic = var.enable_private_only_traffic

  network_id = local.network_id
}

module "private_link" {
  count  = length(var.private_link_allowed_account_ids) > 0 ? 1 : 0
  source = "../../modules/private_link"

  namespace               = var.namespace
  allowed_account_ids     = var.private_link_allowed_account_ids
  deletion_protection     = var.deletion_protection
  network_private_subnets = local.network_private_subnets
  alb_name                = local.lb_name_truncated
  vpc_id                  = local.network_id

  enable_private_only_traffic = var.enable_private_only_traffic
  nlb_security_group          = module.app_lb.nlb_security_group

  depends_on = [
    module.wandb
  ]
}

resource "aws_autoscaling_attachment" "autoscaling_attachment" {
  for_each               = module.app_eks.autoscaling_group_names
  autoscaling_group_name = each.value
  lb_target_group_arn    = module.app_lb.tg_app_arn
}

locals {
  network_elasticache_subnets             = var.network_elasticache_subnets
  network_elasticache_subnet_cidrs        = var.network_elasticache_subnet_cidrs
  network_elasticache_create_subnet_group = true
  network_elasticache_subnet_group_name   = "${var.namespace}-elasticache-subnet"
}

module "redis" {
  count                     = var.create_elasticache ? 1 : 0
  redis_create_subnet_group = local.network_elasticache_create_subnet_group
  redis_subnets             = local.network_elasticache_subnets
  source                    = "../../modules/redis"
  namespace                 = var.namespace

  vpc_id                  = local.network_id
  redis_subnet_group_name = local.network_elasticache_subnet_group_name
  vpc_subnets_cidr_blocks = local.network_elasticache_subnet_cidrs
  node_type               = try(local.deployment_size[var.size].cache, var.elasticache_node_type)
  kms_key_arn             = local.kms_key_arn
}

locals {
  max_lb_name_length = 32 - length("-alb-k8s")
  lb_name_truncated  = "${substr(var.namespace, 0, local.max_lb_name_length)}-alb-k8s"
}

module "wandb" {
  source  = "wandb/wandb/helm"
  version = "2.0.0"

  depends_on = [
    module.app_eks,
    module.redis,
  ]
  operator_chart_version = "1.1.2"
  controller_image_tag   = "1.10.1"

  spec = {
    values = {
      global = {
        host    = local.url
        license = var.license

        extraEnv = var.other_wandb_env

        bucket = var.bucket_name != "" ? {
          provider = "s3"
          name     = var.bucket_name
          region   = data.aws_s3_bucket.file_storage.region
          kmsKey   = var.bucket_kms_key_arn
        } : null

        defaultBucket = {
          provider = "s3"
          name     = module.file_storage.bucket_name
          region   = module.file_storage.bucket_region
          kmsKey   = module.kms.key.arn
        }

        mysql = {
          host     = var.database_endpoint
          password = var.database_master_password
          user     = var.database_master_username
          database = var.database_name
          port     = var.database_port
        }

        redis = {
          host = module.redis.0.host
          port = "${module.redis.0.port}?tls=true&ttlInSeconds=604800"
        }
      }

      ingress = {
        class = "alb"

        additionalHosts = concat(var.extra_fqdn, length(var.private_link_allowed_account_ids) > 0 ? [""] : [])

        annotations = merge({
          "alb.ingress.kubernetes.io/load-balancer-name"             = local.lb_name_truncated
          "alb.ingress.kubernetes.io/inbound-cidrs"                  = <<-EOF
            ${join("\\,", var.allowed_inbound_cidr)}
          EOF
          "external-dns.alpha.kubernetes.io/ingress-hostname-source" = "annotation-only"
          "alb.ingress.kubernetes.io/scheme"                         = var.kubernetes_alb_internet_facing ? "internet-facing" : "internal"
          "alb.ingress.kubernetes.io/target-type"                    = "ip"
          "alb.ingress.kubernetes.io/listen-ports"                   = "[{\\\"HTTPS\\\": 443}]"
          "alb.ingress.kubernetes.io/certificate-arn"                = local.acm_certificate_arn
          },
          length(var.extra_fqdn) > 0 && var.enable_dummy_dns ? {
            "external-dns.alpha.kubernetes.io/hostname" = <<-EOF
              ${local.fqdn}\,${join("\\,", var.extra_fqdn)}\,${local.fqdn}
            EOF
            } : {
            "external-dns.alpha.kubernetes.io/hostname" = var.enable_operator_alb ? local.fqdn : ""
          },
          length(var.kubernetes_alb_subnets) > 0 ? {
            "alb.ingress.kubernetes.io/subnets" = <<-EOF
              ${join("\\,", var.kubernetes_alb_subnets)}
            EOF
        } : {})

      }

      app = var.enable_operator_alb ? {} : {
        extraEnv = merge({
          "GORILLA_GLUE_LIST" = "true"
        }, var.app_wandb_env)
      }

      mysql = { install = false }
      redis = { install = false }

      weave = {
        persistence = {
          provider = "efs"
          efs = {
            fileSystemId = module.app_eks.efs_id
          }
        }
        extraEnv = var.weave_wandb_env
      }

      parquet = {
        extraEnv = var.parquet_wandb_env
      }
    }
  }
}

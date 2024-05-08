provider "aws" {
  region = "us-east-1"


  default_tags {
    tags = {
      GithubRepo = "terraform-aws-wandb"
      GithubOrg  = "wandb"
      Enviroment = "Example"
      Example    = "BYO-VPC-EKS-SQL-REDIS"
    }
  }
}
data "aws_s3_bucket" "file_storage" {
  depends_on = [module.file_storage]
  bucket     = local.bucket_name
}

data "aws_sqs_queue" "file_storage" {
  count      = local.use_internal_queue ? 0 : 1
  depends_on = [module.file_storage]
  name       = local.bucket_queue_name
}

data "aws_eks_cluster" "app_cluster" {
  name = var.eks_cluster_name
}

data "aws_eks_cluster_auth" "app_cluster" {
  name = var.eks_cluster_name
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
  count     = var.create_bucket ? 1 : 0
  source    = "../../modules/file_storage"
  
  create_queue = !local.use_internal_queue
  deletion_protection = var.deletion_protection
  kms_key_arn   = local.kms_key_arn
  namespace = var.namespace
  sse_algorithm = "aws:kms"
}

locals {
  bucket_name       = local.use_external_bucket ? var.bucket_name : module.file_storage.0.bucket_name
  bucket_queue_name = local.use_internal_queue ? null : module.file_storage.0.bucket_queue_name
}

module "networking" {
  source     = "../../modules/networking"
  namespace  = var.namespace
  create_vpc = var.create_vpc

  cidr                      = var.network_cidr
  private_subnet_cidrs      = var.network_private_subnet_cidrs
  public_subnet_cidrs       = var.network_public_subnet_cidrs
  database_subnet_cidrs     = var.network_database_subnet_cidrs
  create_elasticache_subnet = var.create_elasticache
  elasticache_subnet_cidrs  = var.network_elasticache_subnet_cidrs
}

locals {
  network_id             = var.create_vpc ? module.networking.vpc_id : var.network_id
  network_public_subnets = var.create_vpc ? module.networking.public_subnets : var.network_public_subnets

  network_private_subnets      = var.create_vpc ? module.networking.private_subnets : var.network_private_subnets
  network_private_subnet_cidrs = var.create_vpc ? module.networking.private_subnet_cidrs : var.network_private_subnet_cidrs

  network_database_subnets             = var.create_vpc ? module.networking.database_subnets : var.network_database_subnets
  network_database_subnet_cidrs        = var.create_vpc ? module.networking.database_subnet_cidrs : var.network_database_subnet_cidrs
  network_database_create_subnet_group = !var.create_vpc
  network_database_subnet_group_name   = var.create_vpc ? module.networking.database_subnet_group_name : "${var.namespace}-database-subnet"
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

locals {
  full_fqdn  = var.enable_dummy_dns ? "old.${local.fqdn}" : local.fqdn
  extra_fqdn = var.enable_dummy_dns ? [for fqdn in var.extra_fqdn : "old.${fqdn}"] : var.extra_fqdn
}

module "app_lb" {
  source = "../../modules/app_lb"

  namespace             = var.namespace
  load_balancing_scheme = var.public_access ? "PUBLIC" : "PRIVATE"
  acm_certificate_arn   = local.acm_certificate_arn
  zone_id               = var.zone_id

  fqdn                      = local.full_fqdn
  extra_fqdn                = local.extra_fqdn
  allowed_inbound_cidr      = var.allowed_inbound_cidr
  allowed_inbound_ipv6_cidr = var.allowed_inbound_ipv6_cidr
  target_port               = local.internal_app_port

  network_id              = local.network_id
  network_private_subnets = local.network_private_subnets
  network_public_subnets  = local.network_public_subnets
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

  depends_on = [
    module.wandb
  ]
}

resource "aws_autoscaling_attachment" "autoscaling_attachment" {
  for_each               = var.autoscaling_group_names
  autoscaling_group_name = each.value
  lb_target_group_arn    = module.app_lb.tg_app_arn
}

locals {
  network_elasticache_subnets             = var.create_vpc ? module.networking.elasticache_subnets : var.network_elasticache_subnets
  network_elasticache_subnet_cidrs        = var.create_vpc ? module.networking.elasticache_subnet_cidrs : var.network_elasticache_subnet_cidrs
  network_elasticache_create_subnet_group = !var.create_vpc
  network_elasticache_subnet_group_name   = var.create_vpc ? module.networking.elasticache_subnet_group_name : "${var.namespace}-elasticache-subnet"
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
  version = "1.2.0"

  operator_chart_version = "1.1.2"
  controller_image_tag   = "1.10.1"

  spec = {
    values = {
      global = {
        host    = local.url
        license = var.license

        extraEnv = var.other_wandb_env

        bucket = {
          provider = "s3"
          name     = local.bucket_name
          region   = data.aws_s3_bucket.file_storage.region
          kmsKey   = local.use_external_bucket ? var.bucket_kms_key_arn : local.kms_key_arn
        }

        mysql = {
          host     = var.database_endpoint
          password = var.database_master_password
          user     = var.database_master_username
          database = var.database_name
          port     = var.database_port
        }

        redis = {
          host = var.create_elasticache ? module.redis.0.host : var.redis_host
          port = var.create_elasticache ? "${module.redis.0.port}?tls=true&ttlInSeconds=604800" : "${var.redis_port}?tls=true&ttlInSeconds=604800"
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
            fileSystemId = var.efs_id
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


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
  bucket     = var.bucket_name
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

locals {
  kms_key_arn         = var.kms_key_arn
  use_external_bucket = var.bucket_name != ""
  use_internal_queue  = local.use_external_bucket || var.use_internal_queue
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
  bucket_queue_name = local.use_internal_queue ? null : module.file_storage.bucket_queue_name
}

locals {
  network_id              = var.network_id
  network_public_subnets  = var.network_public_subnets
  network_private_subnets = var.network_private_subnets
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
  internal_app_port   = 32543
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
  for_each               = var.autoscaling_group_names
  autoscaling_group_name = each.value
  lb_target_group_arn    = module.app_lb.tg_app_arn
}

locals {
  max_lb_name_length = 32 - length("-alb-k8s")
  lb_name_truncated  = "${substr(var.namespace, 0, local.max_lb_name_length)}-alb-k8s"
}

module "wandb" {
  source  = "wandb/wandb/helm"
  version = "2.0.0"

  depends_on = [
    module.app_lb,
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
          host = var.redis_host
          port = "${var.redis_port}?tls=true&ttlInSeconds=604800"
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

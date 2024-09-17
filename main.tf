module "kms" {
  source = "./modules/kms"

  key_deletion_window = var.kms_key_deletion_window

  key_alias  = var.kms_key_alias == null ? "${var.namespace}-kms-alias" : var.kms_key_alias
  key_policy = var.kms_key_policy

  policy_administrator_arn = var.kms_key_policy_administrator_arn

  create_clickhouse_key = var.enable_clickhouse
  clickhouse_key_alias  = var.kms_clickhouse_key_alias == null ? "${var.namespace}-kms-clickhouse-alias" : var.kms_clickhouse_key_alias
  clickhouse_key_policy = var.kms_clickhouse_key_policy
}

locals {
  default_kms_key                           = module.kms.key.arn
  clickhouse_kms_key                        = var.enable_clickhouse ? module.kms.clickhouse_key.arn : null
  database_kms_key_arn                      = length(var.database_kms_key_arn) > 0 ? var.database_kms_key_arn : local.default_kms_key
  database_performance_insights_kms_key_arn = length(var.database_performance_insights_kms_key_arn) > 0 ? var.database_performance_insights_kms_key_arn : local.default_kms_key
  use_external_bucket                       = var.bucket_name != ""
  s3_kms_key_arn                            = local.use_external_bucket || var.bucket_kms_key_arn != "" ? var.bucket_kms_key_arn : local.default_kms_key
  use_internal_queue                        = local.use_external_bucket || var.use_internal_queue
}

module "file_storage" {
  count               = var.create_bucket ? 1 : 0
  source              = "./modules/file_storage"
  namespace           = var.namespace
  create_queue        = !local.use_internal_queue
  sse_algorithm       = "aws:kms"
  kms_key_arn         = local.s3_kms_key_arn
  deletion_protection = var.deletion_protection
}

locals {
  bucket_name       = local.use_external_bucket ? var.bucket_name : module.file_storage.0.bucket_name
  bucket_queue_name = local.use_internal_queue ? null : module.file_storage.0.bucket_queue_name
}

module "networking" {
  source     = "./modules/networking"
  namespace  = var.namespace
  create_vpc = var.create_vpc

  cidr                           = var.network_cidr
  private_subnet_cidrs           = var.network_private_subnet_cidrs
  public_subnet_cidrs            = var.network_public_subnet_cidrs
  database_subnet_cidrs          = var.network_database_subnet_cidrs
  create_elasticache_subnet      = var.create_elasticache
  elasticache_subnet_cidrs       = var.network_elasticache_subnet_cidrs
  clickhouse_endpoint_service_id = var.clickhouse_endpoint_service_id
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

module "s3_endpoint" {
  count                  = length(var.private_link_allowed_account_ids) > 0 ? 1 : 0
  source                 = "./modules/endpoint"
  service_name           = "com.amazonaws.${data.aws_region.current.name}.s3"
  network_id             = local.network_id
  private_route_table_id = module.networking.private_route_table_ids
  depends_on             = [module.networking]
}

module "database" {
  source = "./modules/database"

  namespace                        = var.namespace
  kms_key_arn                      = local.database_kms_key_arn
  performance_insights_kms_key_arn = local.database_performance_insights_kms_key_arn

  database_name   = var.database_name
  master_username = var.database_master_username

  instance_class      = try(local.deployment_size[var.size].db, var.database_instance_class)
  engine_version      = var.database_engine_version
  snapshot_identifier = var.database_snapshot_identifier
  sort_buffer_size    = var.database_sort_buffer_size

  deletion_protection = var.deletion_protection

  vpc_id                 = local.network_id
  create_db_subnet_group = local.network_database_create_subnet_group
  db_subnet_group_name   = local.network_database_subnet_group_name
  subnets                = local.network_database_subnets

  allowed_cidr_blocks = local.network_private_subnet_cidrs
}

locals {
  create_certificate = var.public_access && var.acm_certificate_arn == null

  fqdn = var.subdomain == null ? var.domain_name : "${var.subdomain}.${var.domain_name}"
}

#Create SSL Ceritifcation if applicable
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
  source = "./modules/app_eks"

  fqdn = local.domain_filter

  namespace   = var.namespace
  kms_key_arn = local.default_kms_key

  instance_types   = try([local.deployment_size[var.size].node_instance], var.kubernetes_instance_types)
  desired_capacity = try(local.deployment_size[var.size].node_count, var.kubernetes_node_count)
  map_accounts     = var.kubernetes_map_accounts
  map_roles        = var.kubernetes_map_roles
  map_users        = var.kubernetes_map_users

  bucket_kms_key_arns = compact([
    local.default_kms_key,
    var.bucket_kms_key_arn != "" && var.bucket_kms_key_arn != null ? var.bucket_kms_key_arn : null
  ])

  bucket_arn           = data.aws_s3_bucket.file_storage.arn
  bucket_sqs_queue_arn = local.use_internal_queue ? null : data.aws_sqs_queue.file_storage.0.arn

  network_id              = local.network_id
  network_private_subnets = local.network_private_subnets

  lb_security_group_inbound_id = module.app_lb.security_group_inbound_id
  database_security_group_id   = module.database.security_group_id

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
}

locals {
  full_fqdn  = var.enable_dummy_dns ? "old.${local.fqdn}" : local.fqdn
  extra_fqdn = var.enable_dummy_dns ? [for fqdn in var.extra_fqdn : "old.${fqdn}"] : var.extra_fqdn
}

module "app_lb" {
  source = "./modules/app_lb"

  namespace             = var.namespace
  load_balancing_scheme = var.public_access ? "PUBLIC" : "PRIVATE"
  acm_certificate_arn   = local.acm_certificate_arn
  zone_id               = var.zone_id

  fqdn                        = local.full_fqdn
  extra_fqdn                  = local.extra_fqdn
  allowed_inbound_cidr        = var.allowed_inbound_cidr
  allowed_inbound_ipv6_cidr   = var.allowed_inbound_ipv6_cidr
  target_port                 = local.internal_app_port
  network_id                  = local.network_id
  network_private_subnets     = local.network_private_subnets
  network_public_subnets      = local.network_public_subnets
  enable_private_only_traffic = var.private_only_traffic
  private_endpoint_cidr       = var.allowed_private_endpoint_cidr

}

module "private_link" {
  count  = length(var.private_link_allowed_account_ids) > 0 ? 1 : 0
  source = "./modules/private_link"

  namespace                   = var.namespace
  allowed_account_ids         = var.private_link_allowed_account_ids
  deletion_protection         = var.deletion_protection
  network_private_subnets     = local.network_private_subnets
  alb_name                    = local.lb_name_truncated
  vpc_id                      = local.network_id
  enable_private_only_traffic = var.private_only_traffic
  nlb_security_group          = module.app_lb.nlb_security_group
  depends_on = [
    module.app_lb,
    module.wandb
  ]
}

resource "aws_autoscaling_attachment" "autoscaling_attachment" {
  for_each               = module.app_eks.autoscaling_group_names
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
  source                    = "./modules/redis"
  namespace                 = var.namespace

  vpc_id                  = local.network_id
  redis_subnet_group_name = local.network_elasticache_subnet_group_name
  vpc_subnets_cidr_blocks = local.network_elasticache_subnet_cidrs
  node_type               = try(local.deployment_size[var.size].cache, var.elasticache_node_type)
  kms_key_arn             = local.database_kms_key_arn
}

locals {
  max_lb_name_length = 32 - length("-alb-k8s")
  lb_name_truncated  = "${substr(var.namespace, 0, local.max_lb_name_length)}-alb-k8s"
}

module "iam_role" {
  count                               = var.enable_yace ? 1 : 0
  source                              = "./modules/iam_role"
  yace_sa_name                        = var.yace_sa_name
  namespace                           = var.namespace
  aws_iam_openid_connect_provider_url = module.app_eks.aws_iam_openid_connect_provider
}

module "wandb" {
  source  = "wandb/wandb/helm"
  version = "1.2.0"

  depends_on = [
    module.database,
    module.app_eks,
    module.redis,
  ]
  controller_image_tag   = "1.13.0"
  operator_chart_version = "1.3.1"

  spec = {
    values = {
      global = {
        host    = local.url
        license = var.license
        licenseSecret = {
          name = var.license_secret_name, ## this will support wandb-operator chart version 0.17.9
          key  = var.license_secret_key_name
        }
        cloudProvider = "aws"
        extraEnv      = var.other_wandb_env

        bucket = {
          provider = "s3"
          name     = local.bucket_name
          path     = var.bucket_path
          region   = data.aws_s3_bucket.file_storage.region
          kmsKey   = local.s3_kms_key_arn
        }

        mysql = {
          host     = module.database.endpoint
          password = module.database.password
          user     = module.database.username
          database = module.database.database_name
          port     = module.database.port
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

      # To support otel rds and redis metrics, we need operator-wandb chart min version 0.13.8 (yace subchart)
      yace = var.enable_yace ? {
        install        = true
        regions        = [data.aws_region.current.name]
        serviceAccount = { annotations = { "eks.amazonaws.com/role-arn" = module.iam_role[0].role_arn } }
        searchTags = {
          "Namespace" = var.namespace
        }
        } : {
        install        = false
        regions        = []
        serviceAccount = {}
        searchTags     = {}
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


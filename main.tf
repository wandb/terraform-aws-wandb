module "kms" {
  source = "./modules/kms"

  key_alias           = var.kms_key_alias == null ? "${var.namespace}-kms-alias" : var.kms_key_alias
  key_deletion_window = var.kms_key_deletion_window

  iam_principal_arn = ""
}

locals {
  kms_key_arn             = module.kms.key.arn
  enable_external_storage = var.bucket_name != ""
}

module "file_storage" {
  count     = local.enable_external_storage ? 0 : 1
  source    = "./modules/file_storage"
  namespace = var.namespace

  create_queue = !var.use_internal_queue

  sse_algorithm = "aws:kms"
  kms_key_arn   = local.kms_key_arn

  deletion_protection = var.deletion_protection
}

locals {
  bucket_name       = local.enable_external_storage ? var.bucket_name : module.file_storage.0.bucket_name
  bucket_queue_name = var.use_internal_queue && local.enable_external_storage ? null : module.file_storage.0.bucket_queue_name
}

data "aws_s3_bucket" "file_storage" {
  depends_on = [module.file_storage]
  bucket     = local.bucket_name
}

data "aws_sqs_queue" "file_storage" {
  count      = local.bucket_queue_name == null ? 0 : 1
  depends_on = [module.file_storage]
  name       = local.bucket_queue_name
}

module "networking" {
  source     = "./modules/networking"
  namespace  = var.namespace
  create_vpc = var.create_vpc

  cidr                  = var.network_cidr
  private_subnet_cidrs  = var.network_private_subnet_cidrs
  public_subnet_cidrs   = var.network_public_subnet_cidrs
  database_subnet_cidrs = var.network_database_subnet_cidrs
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


module "database" {
  source = "./modules/database"

  namespace   = var.namespace
  kms_key_arn = local.kms_key_arn

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

# Create SSL Ceritifcation if applicable
module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 3.0"

  create_certificate = local.create_certificate

  domain_name = var.external_dns ? local.fqdn : var.domain_name
  zone_id     = var.zone_id

  wait_for_validation = true
}

locals {
  acm_certificate_arn = local.create_certificate ? module.acm.acm_certificate_arn : var.acm_certificate_arn
  url                 = local.acm_certificate_arn == null ? "http://${local.fqdn}" : "https://${local.fqdn}"

  internal_app_port = 32543
}

module "app_eks" {
  source = "./modules/app_eks"

  namespace   = var.namespace
  bucket_kms_key_arn = local.enable_external_storage ? var.bucket_kms_key_arn : local.kms_key_arn

  map_accounts = var.kubernetes_map_accounts
  map_roles    = var.kubernetes_map_roles
  map_users    = var.kubernetes_map_users

  bucket_arn           = data.aws_s3_bucket.file_storage.arn
  bucket_sqs_queue_arn = var.use_internal_queue ? null : data.aws_sqs_queue.file_storage.0.arn

  network_id              = local.network_id
  network_private_subnets = local.network_private_subnets

  lb_security_group_inbound_id = module.app_lb.security_group_inbound_id
  database_security_group_id   = module.database.security_group_id

  cluster_endpoint_public_access       = var.kubernetes_public_access
  cluster_endpoint_public_access_cidrs = var.kubernetes_public_access_cidrs
}

module "app_lb" {
  source = "./modules/app_lb"

  namespace             = var.namespace
  load_balancing_scheme = var.public_access ? "PUBLIC" : "PRIVATE"
  acm_certificate_arn   = local.acm_certificate_arn
  zone_id               = var.zone_id

  fqdn                      = local.fqdn
  allowed_inbound_cidr      = var.allowed_inbound_cidr
  allowed_inbound_ipv6_cidr = var.allowed_inbound_ipv6_cidr
  target_port               = local.internal_app_port

  network_id              = local.network_id
  network_private_subnets = local.network_private_subnets
  network_public_subnets  = local.network_public_subnets
}

resource "aws_autoscaling_attachment" "autoscaling_attachment" {
  for_each               = module.app_eks.autoscaling_group_names
  autoscaling_group_name = each.value
  alb_target_group_arn   = module.app_lb.tg_app_arn
}

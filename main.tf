module "kms" {
  source = "./modules/kms"

  key_alias           = var.kms_key_alias
  key_deletion_window = var.kms_key_deletion_window

  iam_principal_arn = ""
}

locals {
  kms_key_arn = module.kms.key.arn
}

module "file_storage" {
  source = "./modules/file_storage"

  namespace   = var.namespace
  kms_key_arn = local.kms_key_arn
}

module "networking" {
  source     = "./modules/networking"
  namespace  = var.namespace
  create_vpc = var.create_vpc

  cidr            = var.network_cidr
  private_subnets = var.network_private_subnets
  public_subnets  = var.network_public_subnets
}

locals {
  network_id              = var.create_vpc ? module.networking.vpc_id : var.network_id
  network_private_subnets = var.create_vpc ? module.networking.private_subnets : var.network_private_subnets
  network_public_subnets  = var.create_vpc ? module.networking.public_subnets : var.network_public_subnets

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

  subject_alternative_names = [local.fqdn]

  wait_for_validation = true
}

locals {
  acm_certificate_arn = local.create_certificate ? module.acm.acm_certificate_arn : var.acm_certificate_arn
  url                 = local.acm_certificate_arn == null ? "http://${local.fqdn}" : "https://${local.fqdn}"

  internal_app_port = 32543
}

module "database" {
  source = "./modules/database"

  namespace   = var.namespace
  kms_key_arn = local.kms_key_arn

  network_id              = local.network_id
  network_private_subnets = local.network_private_subnets
}

module "app_eks" {
  source = "./modules/app_eks"

  namespace   = var.namespace
  kms_key_arn = local.kms_key_arn

  bucket_arn           = module.file_storage.bucket_arn
  bucket_sqs_queue_arn = module.file_storage.bucket_queue_arn

  network_id              = local.network_id
  network_private_subnets = local.network_private_subnets

  lb_security_group_inbound_id = module.app_lb.security_group_inbound_id
  database_security_group_id   = module.database.security_group_id

  cluster_endpoint_public_access = var.kubernetes_public_access
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

data "aws_eks_cluster" "app_cluster" {
  name = module.app_eks.cluster_id
}

data "aws_eks_cluster_auth" "app_cluster" {
  name = module.app_eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.app_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.app_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.app_cluster.token
}

module "app_kube" {
  source = "./modules/app_kube"

  namespace = var.namespace

  wandb_image   = var.wandb_image
  wandb_license = var.wandb_license
  wandb_version = var.wandb_version

  host = local.url

  bucket_name        = module.file_storage.bucket_name
  bucket_region      = module.file_storage.bucket_region
  bucket_queue_name  = module.file_storage.bucket_queue_name
  bucket_kms_key_arn = local.kms_key_arn

  database_connection_string = module.database.connection_string

  service_port = local.internal_app_port
}
locals {
  fqdn = "${var.subdomain}.${var.domain_name}"
}

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "key" {
  deletion_window_in_days = var.kms_key_deletion_window
  description             = "AWS KMS Customer-managed key to encrypt Weights & Biases resources"
  enable_key_rotation     = false
  is_enabled              = true
  key_usage               = "ENCRYPT_DECRYPT"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Allow administration of the key",
        "Effect" : "Allow",
        "Principal" : { "AWS" : "${data.aws_caller_identity.current.arn}" },
        "Action" : [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "Allow use of the key",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : [
            "s3.amazonaws.com",
            "sqs.amazonaws.com",
            "rds.amazonaws.com",
            "eks.amazonaws.com"
          ]
        },
        "Action" : [
          "kms:GenerateDataKey",
          "kms:Decrypt"
        ],
        "Resource" : "*"
      }
    ]
  })

  tags = {
    Name = "wandb-kms-key"
  }
}

resource "aws_kms_alias" "key_alias" {
  name          = "alias/${var.namespace}-${var.kms_key_alias}"
  target_key_id = aws_kms_key.key.key_id
}


locals {
  kms_key_arn = aws_kms_key.key.arn
}

module "file_storage" {
  source = "./modules/file_storage"

  namespace   = var.namespace
  kms_key_arn = local.kms_key_arn
}

module "networking" {
  count = var.deploy_vpc ? 1 : 0

  source = "./modules/networking"

  namespace                    = var.namespace
  network_cidr                 = var.network_cidr
  network_private_subnet_cidrs = var.network_private_subnet_cidrs
  network_public_subnet_cidrs  = var.network_public_subnet_cidrs
}

locals {
  network_id              = var.deploy_vpc ? module.networking[0].vpc_id : var.network_id
  network_private_subnets = var.deploy_vpc ? module.networking[0].private_subnets : var.network_private_subnets
  network_public_subnets  = var.deploy_vpc ? module.networking[0].public_subnets : var.network_public_subnets
}

module "dns" {
  source = "./modules/dns"

  is_subdomain_zone = var.is_subdomain_zone

  namespace           = var.namespace
  domain_name         = var.domain_name
  subdomain           = var.subdomain
  acm_certificate_arn = var.acm_certificate_arn
}

module "app_load_balancer" {
  source = "./modules/app_load_balancer"

  namespace             = var.namespace
  load_balancing_scheme = var.load_balancing_scheme
  acm_certificate_arn   = module.dns.acm_certificate_arn
  zone_id               = module.dns.zone_id

  fqdn                    = local.fqdn
  allowed_inbound_cidr    = var.allowed_inbound_cidr
  network_id              = local.network_id
  network_private_subnets = local.network_private_subnets
  network_public_subnets  = local.network_public_subnets
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

  lb_security_group_inbound_id = module.app_load_balancer.security_group_inbound_id
  database_security_group_id   = module.database.security_group_id
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

  namespace   = var.namespace
  kms_key_arn = var.kms_key_alias

  wandb_image   = var.wandb_image
  wandb_license = var.wandb_license
  wandb_version = var.wandb_version

  bucket_name       = module.file_storage.bucket_name
  bucket_region     = module.file_storage.bucket_region
  bucket_queue_name = module.file_storage.bucket_queue_name

  database_connection_string = module.database.connection_string
}
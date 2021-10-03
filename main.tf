locals {
  fqdn = "${var.subdomain}.${var.domain_name}"
}

resource "aws_kms_key" "key" {
  deletion_window_in_days = var.kms_key_deletion_window
  description             = "AWS KMS Customer-managed key to encrypt Weights & Biases and other resources"
  enable_key_rotation     = false
  is_enabled              = true
  key_usage               = "ENCRYPT_DECRYPT"

  tags = {
    Name = "wandb-kms-key"
  }
}

resource "aws_kms_alias" "key_alias" {
  name          = "alias/${local.namespace}-${var.kms_key_alias}"
  target_key_id = aws_kms_key.key.key_id
}

module "object_storage" {
  source = "./modules/object_storage"

  namespace   = local.namespace
  kms_key_arn = aws_kms_key.key.arn
}

module "networking" {
  count = var.deploy_vpc ? 1 : 0

  source = "./modules/networking"

  namespace                    = local.namespace
  network_cidr                 = var.network_cidr
  network_private_subnet_cidrs = var.network_private_subnet_cidrs
  network_public_subnet_cidrs  = var.network_public_subnet_cidrs
}

locals {
  network_id                   = var.deploy_vpc ? module.networking[0].network_id : var.network_id
  network_private_subnets      = var.deploy_vpc ? module.networking[0].network_private_subnets : var.network_private_subnets
  network_public_subnets       = var.deploy_vpc ? module.networking[0].network_public_subnets : var.network_public_subnets
  network_private_subnet_cidrs = var.deploy_vpc ? module.networking[0].network_private_subnet_cidrs : var.network_private_subnet_cidrs
}

module "database" {
  source = "./modules/database"

  namespace   = local.namespace
  kms_key_arn = aws_kms_key.key.arn

  network_id              = local.network_id
  network_private_subnets = local.network_private_subnets
}

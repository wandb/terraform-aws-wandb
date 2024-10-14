terraform {
  backend "s3" {
    bucket = "<bucket-name>" #TODO: Replace with bucket name where you want to store the Terraform state
    key    = "wandb-tf-state"
    region = "<region-name>" #TODO: Replace if region is different
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.6"
    }
  }
}

provider "aws" {
  region = "<region-name>" #TODO: Replace this with region name

  default_tags {
    tags = {
      GithubRepo  = "terraform-aws-wandb"
      GithubOrg   = "wandb"
      Environment = "Production"
    }
  }
}

module "wandb_infra" {
  source  = "wandb/wandb/aws"
  version = "3.0.0"

  namespace     = var.namespace
  public_access = true
  external_dns  = true

  create_vpc = false

  network_id   = var.vpc_id
  network_cidr = var.vpc_cidr

  network_private_subnets       = var.network_private_subnets
  network_public_subnets        = var.network_public_subnets
  network_database_subnets      = var.network_database_subnets
  network_private_subnet_cidrs  = var.network_private_subnet_cidrs
  network_public_subnet_cidrs   = var.network_public_subnet_cidrs
  network_database_subnet_cidrs = var.network_database_subnet_cidrs

  deletion_protection = false

  database_instance_class      = var.database_instance_class
  database_engine_version      = var.database_engine_version
  database_snapshot_identifier = var.database_snapshot_identifier
  database_sort_buffer_size    = var.database_sort_buffer_size

  allowed_inbound_cidr      = var.allowed_inbound_cidr
  allowed_inbound_ipv6_cidr = ["::/0"]

  eks_cluster_version            = var.eks_cluster_version
  kubernetes_public_access       = true
  kubernetes_public_access_cidrs = ["0.0.0.0/0"]

  create_elasticache = false

  domain_name = var.domain_name
  zone_id     = var.zone_id
  subdomain   = var.subdomain

  bucket_name        = var.bucket_name
  bucket_kms_key_arn = var.bucket_kms_key_arn
  use_internal_queue = true
}

data "aws_eks_cluster" "app_cluster" {
  name = module.wandb_infra.cluster_name
}

data "aws_eks_cluster_auth" "app_cluster" {
  name = module.wandb_infra.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.app_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.app_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.app_cluster.token
}

module "wandb_app" {
  source = "github.com/wandb/terraform-kubernetes-wandb"

  license = var.wandb_license

  host                       = module.wandb_infra.url
  bucket                     = "s3://${module.wandb_infra.bucket_name}"
  bucket_aws_region          = module.wandb_infra.bucket_region
  bucket_queue               = "internal://"
  bucket_kms_key_arn         = module.wandb_infra.kms_key_arn
  database_connection_string = "mysql://${module.wandb_infra.database_connection_string}"

  wandb_image   = var.wandb_image
  wandb_version = var.wandb_version

  service_port = module.wandb_infra.internal_app_port

  depends_on = [module.wandb_infra]
}

output "bucket_name" {
  value = module.wandb_infra.bucket_name
}

output "bucket_queue_name" {
  value = module.wandb_infra.bucket_queue_name
}

provider "aws" {
  region = "us-west-2"


  default_tags {
    tags = {
      GithubRepo = "terraform-aws-wandb"
      GithubOrg  = "wandb"
      Enviroment = "Example"
      Example    = "PublicDnsExternal"
    }
  }
}

module "wandb_infra" {
  source = "../../"

  namespace     = var.namespace
  public_access = true
  external_dns  = true

  deletion_protection = true

  create_vpc = false

  size = "medium"

  network_id   = var.vpc_id
  network_cidr = var.vpc_cidr

  network_private_subnets       = var.network_private_subnets
  network_public_subnets        = var.network_public_subnets
  network_database_subnets      = var.network_database_subnets
  network_private_subnet_cidrs  = var.network_private_subnet_cidrs
  network_public_subnet_cidrs   = var.network_public_subnet_cidrs
  network_database_subnet_cidrs = var.network_database_subnet_cidrs
  network_elasticache_subnets   = var.network_elasticache_subnets

  database_instance_class      = var.database_instance_class
  database_engine_version      = var.database_engine_version
  database_snapshot_identifier = var.database_snapshot_identifier
  database_sort_buffer_size    = var.database_sort_buffer_size

  allowed_inbound_cidr      = var.allowed_inbound_cidr
  allowed_inbound_ipv6_cidr = ["::/0"]

  eks_cluster_version            = var.eks_cluster_version
  kubernetes_public_access       = true
  kubernetes_public_access_cidrs = ["0.0.0.0/0"]

  domain_name = var.domain_name
  zone_id     = var.zone_id
  subdomain   = var.subdomain

  license = var.wandb_license

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

module "wandb_app" {
  source  = "wandb/wandb/kubernetes"
  version = "1.12.0"

  license = var.wandb_license

  host                       = module.wandb_infra.url
  bucket                     = "s3://${module.wandb_infra.bucket_name}"
  bucket_aws_region          = module.wandb_infra.bucket_region
  bucket_queue               = "internal://"
  bucket_kms_key_arn         = module.wandb_infra.kms_key_arn
  database_connection_string = "mysql://${module.wandb_infra.database_connection_string}"
  redis_connection_string    = "redis://${module.wandb_infra.elasticache_connection_string}?tls=true&ttlInSeconds=604800"

  wandb_image   = var.wandb_image
  wandb_version = var.wandb_version

  service_port = module.wandb_infra.internal_app_port

  # If we dont wait, tf will start trying to deploy while the work group is
  # still spinning up
  depends_on = [module.wandb_infra]

  other_wandb_env = merge({
    "GORILLA_CUSTOMER_SECRET_STORE_SOURCE" = "aws-secretmanager://${var.namespace}?namespace=${var.namespace}"
  }, var.other_wandb_env)
}

output "bucket_name" {
  value = module.wandb_infra.bucket_name
}

output "bucket_queue_name" {
  value = module.wandb_infra.bucket_queue_name
}

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

  deletion_protection = false

  database_instance_class      = var.database_instance_class
  database_engine_version      = var.database_engine_version
  database_snapshot_identifier = var.database_snapshot_identifier
  database_sort_buffer_size    = var.database_sort_buffer_size

  allowed_inbound_cidr      = var.allowed_inbound_cidr
  allowed_inbound_ipv6_cidr = ["::/0"]

  eks_cluster_version            = "1.29"
  kubernetes_public_access       = true
  kubernetes_public_access_cidrs = ["0.0.0.0/0"]

  domain_name = var.domain_name
  zone_id     = var.zone_id
  subdomain   = var.subdomain

  license = var.wandb_license

  bucket_name        = var.bucket_name
  bucket_path        = var.bucket_path
  bucket_kms_key_arn = var.bucket_kms_key_arn
  use_internal_queue = true
  size               = var.size

  system_reserved_cpu_millicores      = var.system_reserved_cpu_millicores
  system_reserved_memory_megabytes    = var.system_reserved_memory_megabytes
  system_reserved_ephemeral_megabytes = var.system_reserved_ephemeral_megabytes
  system_reserved_pid                 = var.system_reserved_pid

  aws_loadbalancer_controller_tags = var.aws_loadbalancer_controller_tags
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

# Migration module: Migrate the public DNS to private DNS
# This will include moving from a public ALB to a private NLB and updating the DNS records
module "migrate_public_to_private" {
  count = var.migrate_public_to_private ? 1 : 0

  source = "../../modules/migrate-public-to-private/"

  namespace              = var.namespace
  subdomain              = var.subdomain
  private_hosted_zone_id = var.private_hosted_zone_id

  vpc_id         = module.wandb_infra.network_id
  subnet_ids     = module.wandb_infra.network_private_subnets
  vpc_cidr_block = module.wandb_infra.network_cidr
}


output "bucket_name" {
  value = module.wandb_infra.bucket_name
}

output "bucket_path" {
  value = module.wandb_infra.bucket_path
}

output "bucket_queue_name" {
  value = module.wandb_infra.bucket_queue_name
}

output "database_instance_type" {
  value = module.wandb_infra.database_instance_type
}

output "eks_node_instance_type" {
  value = module.wandb_infra.eks_node_instance_type
}

output "redis_instance_type" {
  value = module.wandb_infra.redis_instance_type
}

output "standardized_size" {
  value = var.size
}

output "network_id" {
  value = module.wandb_infra.network_id
}

output "network_private_subnets" {
  value = module.wandb_infra.network_private_subnets
}

output "network_private_subnet_cidrs" {
  value = module.wandb_infra.network_private_subnet_cidrs
}

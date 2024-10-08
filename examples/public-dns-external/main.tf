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

  eks_cluster_version            = "1.26"
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
  name = module.wandb_infra.cluster_id
}

data "aws_eks_cluster_auth" "app_cluster" {
  name = module.wandb_infra.cluster_id
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
  bucket_path                = var.bucket_path
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

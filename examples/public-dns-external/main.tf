# this assumes your shell is authenticated with gcloud and using playground-111:
# gcloud config set project playground-111
# gcloud auth application-default login
terraform {
  backend "gcs" {
    bucket = "install.wandb.ai"
    prefix = "cvp.wandb.ml"
  }
}

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
  allowed_inbound_ipv6_cidr = var.allowed_inbound_ipv6_cidr

  eks_cluster_version            = "1.25"
  kubernetes_public_access       = true
  kubernetes_public_access_cidrs = ["0.0.0.0/0"]
  kubernetes_instance_types      = ["m6a.2xlarge"] # 8 vCPU, 32 GiB RAM

  domain_name = var.domain_name
  zone_id     = var.zone_id
  subdomain   = var.subdomain

  bucket_name        = var.bucket_name
  bucket_kms_key_arn = var.bucket_kms_key_arn
  use_internal_queue = true
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
}

module "wandb_app" {
  # source = "github.com/wandb/terraform-kubernetes-wandb"
  source = "../../../terraform-kubernetes-wandb"

  license = var.wandb_license

  oidc_client_id = var.oidc_client_id
  oidc_issuer = var.oidc_issuer

  other_wandb_secrets = var.other_wandb_secrets

  dd_env = var.datadog_env
  weave_enabled = true
  weave_enable_datadog = true
  weave_dd_profiling_enabled = true
  weave_storage_class = "ebs-sc"
  weave_storage_provisioner = "ebs.csi.aws.com"
  weave_storage_type = "gp3"
  weave_storage_size = "250Gi"
  parquet_enabled = true

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
}

output "bucket_name" {
  value = module.wandb_infra.bucket_name
}

output "bucket_queue_name" {
  value = module.wandb_infra.bucket_queue_name
}

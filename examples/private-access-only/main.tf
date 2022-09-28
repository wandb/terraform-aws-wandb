provider "aws" {
  region = "us-east-2"

  default_tags {
    tags = {
      GithubRepo = "terraform-aws-wandb"
      GithubOrg  = "wandb"
      Enviroment = "Example"
      Example    = "PrivateAccessOnly"
    }
  }
}

module "wandb_infra" {
  source = "../../"

  namespace = var.namespace

  public_access            = false
  kubernetes_public_access = false

  domain_name = var.domain
}

module "wandb_app" {
  source = "github.com/wandb/terraform-kubernetes-wandb"

  license = var.wandb_license

  host                       = module.wandb_infra.url
  bucket                     = "s3://${module.wandb_infra.bucket_name}"
  bucket_aws_region          = module.wandb_infra.bucket_region
  bucket_queue               = "sqs://${module.wandb_infra.bucket_queue_name}"
  bucket_kms_key_arn         = module.wandb_infra.kms_key_arn
  database_connection_string = "mysql://${module.wandb_infra.database_connection_string}"

  service_port = module.wandb_infra.internal_app_port

  # If we dont wait, tf will start trying to deploy while the work group is
  # still spinning up
  depends_on = [module.wandb_infra]
}

output "url" {
  value = module.wandb_infra.url
}
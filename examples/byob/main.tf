provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      GithubRepo = "terraform-aws-wandb"
      GithubOrg  = "wandb"
      Enviroment = "Example"
      Example    = "BringYourOwnBucket"
    }
  }
}

locals {
  namespace = "wandb-resources-1"

  # Weights & Biases Deployment Account
  wandb_deployment_account_id = "830241207209"
  # wandb_deployment_account_id = "250180789729"
}

module "resources" {
  source = "../../modules/file_storage"

  namespace     = local.namespace
  sse_algorithm = "AES256"

  # We'll create our own custom policy so the trusted account can access these
  # resources
  create_queue        = false
  create_queue_policy = false

  deletion_protection = false
}

module "resources_access" {
  source = "../../modules/file_storage_external"

  namespace          = local.namespace
  trusted_account_id = local.wandb_deployment_account_id
  bucket_arn         = module.resources.bucket_arn
  bucket_name        = module.resources.bucket_name
}

output "bucket_name" {
  value = module.resources.bucket_name
}

output "bucket_queue_name" {
  value = module.resources.bucket_queue_name
}

output "bucket_queue_arn" {
  value = module.resources.bucket_queue_arn
}
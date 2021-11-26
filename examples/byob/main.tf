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
  namespace = "my-wandb-resources"

  # Weights & Biases Deployment Account
  wandb_deployment_account_id = "250180789729"
}

module "resources" {
  source = "../../modules/file_storage"

  namespace           = local.namespace
  sse_algorithm       = "AES256"
  create_queue_policy = false

  deletion_protection = false
}

module "resources_access" {
  source = "../../modules/file_storage_external"

  namespace          = local.namespace
  trusted_account_id = local.wandb_deployment_account_id
  bucket_arn         = module.resources.bucket_arn
  bucket_name        = module.resources.bucket_name
  bucket_queue_arn   = module.resources.bucket_queue_arn
  bucket_queue_name  = module.resources.bucket_queue_name
}

output "bucket_arn" {
  value = module.resources.bucket_arn
}

output "bucket_name" {
  value = module.resources.bucket_name
}

output "bucket_queue_arn" {
  value = module.resources.bucket_queue_arn
}

output "bucket_queue_name" {
  value = module.resources.bucket_queue_name
}

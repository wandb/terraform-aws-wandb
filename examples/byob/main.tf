
variable "bucket_prefix" {
  type        = string
  description = "Prefix of your bucket"
}

variable "region" {
  type        = string
  description = "AWS region the bucket will live in."
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      GithubRepo = "terraform-aws-wandb"
      GithubOrg  = "wandb"
      Enviroment = "BringYourOwnBucket"
      Namespace  = "WeightsBiases"
    }
  }
}

locals {
  namespace = var.bucket_prefix

  # Weights & Biases Deployment Account
  wandb_deployment_account_id  = "830241207209"
  wandb_deployment_account_arn = "arn:aws:iam::${local.wandb_deployment_account_id}:root"
}

resource "byob" {
  source = "../modules/byob"

  bucket_prefix = var.bucket_prefix
}

output "bucket_name" {
  value = module.byob.bucket_name
}

output "bucket_kms_key_arn" {
  value = module.byob.bucket_kms_key_arn
}
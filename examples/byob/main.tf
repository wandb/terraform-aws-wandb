
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


module "secure_storage_connector" {
  source            = "wandb/wandb/aws//modules/secure_storage_connector"
  namespace         = local.namespace
  aws_principal_arn = local.wandb_deployment_account_arn
}

output "bucket_name" {
  value = module.secure_storage_connector.bucket.bucket
}

output "bucket_kms_key_arn" {
  value = module.secure_storage_connector.bucket_kms_key.arn
}


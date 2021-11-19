provider "aws" {
  region = "us-east-2"

  default_tags {
    tags = {
      GithubRepo = "terraform-aws-wandb"
      GithubOrg  = "wandb"
      Enviroment = "Example"
      Example    = "BringYourOwnBucket"
    }
  }
}

module "wandb" {
  source = "../../"

  namespace = var.namespace

  public_access = true
  wandb_license = var.wandb_license
}
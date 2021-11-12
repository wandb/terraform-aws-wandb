provider "aws" {
  region = "us-east-2"

  default_tags {
    tags = {
      GithubRepo = "terraform-aws-wandb"
      GithubOrg  = "wandb"
      Enviroment = "Example"
      Example    = "PublicDnsOnRoute53"
    }
  }
}

module "standard" {
  source = "../../"

  public_access = true

  namespace   = var.namespace
  domain_name = var.domain_name
  subdomain   = var.subdomain

  wandb_license = var.license
}
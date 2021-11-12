provider "aws" {
  region = "us-east-2"

  default_tags {
    tags = {
      GithubRepo = "terraform-aws-wandb"
      GithubOrg  = "wandb"
      Enviroment = "Example"
      Example    = "PublicDnsExternal"
    }
  }
}

module "standard" {
  source = "../../"

  public_access = true
  external_dns  = true

  namespace   = var.namespace
  domain_name = var.domain_name
  subdomain   = var.subdomain

  wandb_license = var.license
}
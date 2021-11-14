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

  namespace     = var.namespace
  public_access = true
  external_dns  = true

  domain_name = var.domain_name
  zone_id     = var.zone_id
  subdomain   = var.subdomain

  wandb_license = var.wandb_license
}
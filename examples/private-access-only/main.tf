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

  public_access = false

  namespace   = var.namespace
  domain_name = var.domain_name
  subdomain   = var.subdomain

  wandb_license = var.license
}

# We'll need a private hosted zone for the domain
resource "aws_route53_zone" "private" {
  name = var.domain_name

  vpc {
    vpc_id = module.standard.network_id
  }
}
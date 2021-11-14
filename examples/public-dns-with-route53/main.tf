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

resource "aws_route53_zone" "public" {
  name = var.domain
}

module "standard" {
  source = "../../"

  namespace     = var.namespace
  public_access = true

  dns_zone_id   = aws_route53_zone.public.zone_id
  dns_subdomain = var.subdomain

  wandb_license = var.license
}
provider "aws" {
  region = "us-east-2"

  default_tags {
    tags = {
      GithubRepo = "terraform-aws-wandb"
      GithubOrg  = "wandb"
      Name       = "WandbLocalTerraform"
      Enviroment = "Testing"
      Example    = "DnsExternal"
    }
  }
}

module "standard" {
  source = "../../"

  is_subdomain_zone = true
  namespace         = var.namespace
  domain_name       = var.domain_name
  subdomain         = var.subdomain
}
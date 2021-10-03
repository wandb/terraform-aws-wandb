provider "aws" {
  region = "us-east-1"
}

module "standard" {
  source = "../../"

  namespace   = var.namespace
  domain_name = var.domain_name
  subdomain   = var.subdomain
}
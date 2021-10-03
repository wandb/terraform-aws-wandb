provider "aws" {
  region  = "us-east-1"
  profile = "default"
}

module "standard" {
  source = "../../"

  namespace = var.namespace
}
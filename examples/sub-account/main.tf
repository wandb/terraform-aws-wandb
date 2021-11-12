locals {
  region            = "us-east-2"
  organization      = "Test2"
  deployment        = "Production"
  account_name      = "tf-test"
  organization_unit = "ou-d5ii-7vudq3sl"
}

provider "aws" {
  region = local.region

  default_tags {
    tags = {
      GithubRepo = "terraform-aws-wandb"
      GithubOrg  = "wandb"
      Name       = "WandbLocalTerraform"
      Enviroment = "Testing"
      Example    = "SubAccount"
    }
  }
}

locals {
  organization_slug = lower(trimspace(local.organization))
  deployment_slug   = lower(trimspace(local.deployment))
}

resource "aws_organizations_account" "account" {
  name      = "${local.organization_slug}-${local.deployment_slug}"
  email     = "${local.organization_slug}-${local.deployment_slug}@wandb.ai"
  parent_id = local.organization_unit

  iam_user_access_to_billing = "ALLOW"
}

provider "aws" {
  alias  = "account"
  region = local.region

  assume_role {
    role_arn = "arn:aws:iam::${aws_organizations_account.account.id}:role/OrganizationAccountAccessRole"
  }
}

resource "aws_s3_bucket" "b" {
  provider = aws.account
  bucket   = "${local.organization_slug}-${local.deployment_slug}"
  acl      = "private"
}
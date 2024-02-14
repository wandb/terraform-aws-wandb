locals {
  infra_outputs           = data.terraform_remote_state.infra.outputs
  gcp_credentials         = local.infra_outputs.deployments_credentials
  aws_deployment_role_arn = local.infra_outputs.deployments_aws_role_arn
  region = "us-west-1"
}

data "terraform_remote_state" "infra" {
  backend = "remote"
  config = {
    organization = "weights-and-biases"
    workspaces   = { name = "deployer-global" }
  }
}

provider "aws" {
  region     = local.region
  access_key = module.aws_credentials.access_key
  secret_key = module.aws_credentials.secret_key
  token      = module.aws_credentials.token

  default_tags {
    tags = {
      Owner          = "Deployer"
      Namespace      = var.namespace
    }
  }
}

# Login using the deployment service account.
provider "google" {
  project     = "wandb-production"
  region      = "us-central1"
  zone        = "us-central1-c"
  credentials = local.gcp_credentials
}

# Create AWS credentials from GCP account
module "aws_credentials" {
  source  = "wandb/assume-aws-role/google"
  version = "1.1.0"

  duration_seconds = 43200 # 12 hours
  role_arn         = local.aws_deployment_role_arn
  session_name     = "TerraformDeployment"
}

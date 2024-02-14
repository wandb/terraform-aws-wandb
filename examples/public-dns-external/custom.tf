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

provider "kubernetes" {
  host                   = data.aws_eks_cluster.app_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.app_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.app_cluster.token

  # To ensure the Kubernetes provider is receiving valid credentials, an
  # exec-based plugin can be used to fetch a new token before initializing the
  # provider.
  exec {
    api_version = "client.authentication.k8s.io/v1"
    args = [
      "eks", "get-token",
      "--cluster-name", module.wandb_infra.cluster_id,
      "--region", local.region,
      "--role-arn", local.aws_deployment_role_arn
    ]
    command = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.app_cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.app_cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.app_cluster.token
  }
}

# Create AWS credentials from GCP account
module "aws_credentials" {
  source  = "wandb/assume-aws-role/google"
  version = "1.1.0"

  duration_seconds = 43200 # 12 hours
  role_arn         = local.aws_deployment_role_arn
  session_name     = "TerraformDeployment"
}

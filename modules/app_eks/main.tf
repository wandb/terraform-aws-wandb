locals {
  cluster_version = "1.20"
  region          = ""
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 17.23"

  cluster_name    = var.namespace
  cluster_version = local.cluster_version

  vpc_id  = var.network_id
  subnets = var.network_private_subnets

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_encryption_config = [
    {
      provider_key_arn = var.kms_key_arn
      resources        = ["secrets"]
    }
  ]

  worker_groups = [
    {
      name                 = "worker-group-1"
      instance_type        = "t3.small"
      asg_desired_capacity = 2
    },
  ]

  tags = {
    GithubRepo         = "wandb"
    GithubOrg          = "terraform-aws-wandb"
    TerraformNamespace = var.namespace
    TerraformModule    = "terraform-aws-wandb/module/app_eks"
  }
}
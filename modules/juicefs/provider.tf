provider "kubernetes" {
  host                   = data.aws_eks_cluster.wandb.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.wandb.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.wandb.token
}

provider "helm" {
  experiments {
    manifest = true
  }
  kubernetes {
    host                   = data.aws_eks_cluster.wandb.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.wandb.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.wandb.token
  }
}
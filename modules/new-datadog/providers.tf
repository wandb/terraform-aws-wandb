terraform {
  cloud {
    organization = "weights-and-biases"

    workspaces {
      tags = ["deployer", "aws"]
    }
  }

}


provider "helm" {
  kubernetes {
    cluster_ca_certificate = var.k8s_cluster_ca_certificate
    host                   = var.k8s_host
    token                  = var.k8s_token

    #exec {
    #    api_version = "client.authentication.k8s.io/v1beta1"
    #    args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
    #    command     = "aws"
    #}
  }
}



terraform {
  required_version = "~> 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.1.1"
    }


    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.6"
    }
  }
}



terraform {
  # backend "s3" {
  #   bucket = "<bucket-name>" #TODO: Replace with bucket name where you want to store the Terraform state
  #   key    = "wandb-tf-state"
  #   region = "<region-name>" #TODO: Replace if region is different
  # }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.6"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }
}

provider "aws" {
  region = var.region #"<region-name>" #TODO: Replace this with region name

  default_tags {
    tags = {
      GithubRepo  = "terraform-aws-wandb"
      GithubOrg   = "wandb"
      App        = "wandb"
      Environment = "Production"
    }
  }
}

# Create database only if create_database is true
module "database" {
  count  = var.create_database ? 1 : 0
  source = "../../modules/database"

  namespace = var.namespace

  database_name   = "wandb"
  master_username = "wandb"

  instance_class      = var.database_instance_class
  engine_version      = var.database_engine_version
  snapshot_identifier = var.database_snapshot_identifier
  sort_buffer_size    = var.database_sort_buffer_size

  deletion_protection = false

  vpc_id                 = var.vpc_id
  create_db_subnet_group = true
  db_subnet_group_name   = "${var.namespace}-database-subnet"
  subnets                = var.network_database_subnets

  allowed_cidr_blocks = var.network_private_subnet_cidrs

  kms_key_arn                      = var.bucket_kms_key_arn
  performance_insights_kms_key_arn = var.bucket_kms_key_arn
}

# Local values for database connection
locals {
  database_connection_string = var.create_database ? "mysql://${module.database[0].username}:${module.database[0].password}@${module.database[0].endpoint}:${module.database[0].port}/${module.database[0].database_name}" : var.existing_database_connection_string
}

data "aws_eks_cluster" "app_cluster" {
  name = var.existing_eks_cluster_name
}

data "aws_eks_cluster_auth" "app_cluster" {
  name = var.existing_eks_cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.app_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.app_cluster.certificate_authority[0].data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.app_cluster.name]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.app_cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.app_cluster.certificate_authority[0].data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.app_cluster.name]
      command     = "aws"
    }
  }
}

# The wandb app deployment is commented out because it requires infrastructure resources
# that are not created when using BYO EKS cluster. You'll need to:
# 1. Manually create RDS database, S3 bucket, KMS keys, etc.
# 2. Update the variables below with your actual resource values
# 3. Uncomment this module

# module "wandb_app" {
#   source  = "wandb/wandb/kubernetes"
#   license = var.wandb_license

#   host                       = "https://${var.subdomain}.${var.domain_name}"
#   bucket                     = "s3://${var.bucket_name}"
#   bucket_aws_region          = var.region
#   bucket_queue               = "internal://"
#   bucket_kms_key_arn         = var.bucket_kms_key_arn
#   database_connection_string = local.database_connection_string

#   wandb_image   = var.wandb_image
#   wandb_version = var.wandb_version

#   service_port = 32543

#   depends_on = [module.database]
# }


locals {
  fqdn = "${var.subdomain}.${var.domain_name}"
  url  = "https://${local.fqdn}"
}

# WandB Helm Chart Configuration for BYO EKS
locals {
  spec = {
    values = {
      global = {
        host          = local.url
        license       = var.wandb_license
        cloudProvider = "aws"
        extraEnv      = var.other_wandb_env != null ? var.other_wandb_env : {}

        bucket = {
          provider = "s3"
          name     = var.bucket_name
          region   = var.region
          kmsKey   = var.bucket_kms_key_arn
        }

        mysql = var.create_database ? {
          host     = module.database[0].endpoint
          password = module.database[0].password
          user     = module.database[0].username
          database = module.database[0].database_name
          port     = module.database[0].port
        } : {
          host     = var.mysql_host
          password = var.mysql_password
          user     = var.mysql_user
          database = var.mysql_database
          port     = var.mysql_port
        }

        redis = {
          host     = ""
          port     = 6379
          external = false
        }
      }

      ingress = {
        class = "alb"
        annotations = {
          "alb.ingress.kubernetes.io/scheme"          = "internet-facing"
          "alb.ingress.kubernetes.io/target-type"     = "ip"
          "alb.ingress.kubernetes.io/listen-ports"    = "[{\\\"HTTPS\\\": 443}]"
          "alb.ingress.kubernetes.io/inbound-cidrs"   = join(",", var.allowed_inbound_cidr)
          "external-dns.alpha.kubernetes.io/hostname" = local.fqdn
        }
      }

      mysql = { install = false }
      redis = { install = true }
    }
  }
}

module "wandb" {
  source  = "wandb/wandb/helm"
  version = "3.0.0"

  depends_on = [
    module.database
  ]

  operator_chart_version   = var.operator_chart_version
  controller_image_tag     = var.controller_image_tag
  enable_helm_operator     = var.enable_helm_operator
  enable_helm_wandb        = var.enable_helm_wandb
  operator_chart_namespace = var.operator_chart_namespace
  wandb_namespace          = var.wandb_chart_namespace

  spec = local.spec
}
output "cluster_name" {
  value = var.existing_eks_cluster_name
}

output "wandb_url" {
  value = local.url
}

# These outputs are only available when infrastructure modules are uncommented:
# output "bucket_name" {
#   value = module.wandb_infra.bucket_name
# }
# 
# output "database_connection_string" {
#   value = module.wandb_infra.database_connection_string
#   sensitive = true
# }
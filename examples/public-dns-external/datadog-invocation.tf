variable "dd_api_key" {
  nullable = true
  type     = string
}

variable "dd_app_key" {
  nullable = true
  type     = string
}

variable "dd_site" {
  nullable = true
  type     = string
}

 module "datadog" {
   source                     = "../../modules/new-datadog"
   cloud_provider_tag         = "aws"
   cluster_name               = module.wandb_infra.cluster_id
   database_tag               = "managed"
   api_key                 = var.dd_api_key
   app_key                 = var.dd_app_key
   site                    = var.dd_site
   environment_tag            = "managed-install"
   k8s_cluster_ca_certificate = base64decode(data.aws_eks_cluster.app_cluster.certificate_authority[0].data)
   k8s_host                   = data.aws_eks_cluster.app_cluster.endpoint
   k8s_token                  = data.aws_eks_cluster_auth.app_cluster.token
   namespace                  = var.namespace
   objectstore_tag            = "managed"
 }
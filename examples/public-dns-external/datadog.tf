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
  cluster_name               = module.wandb_infra.cluster_id
  dd_api_key                 = var.dd_api_key
  dd_app_key                 = var.dd_app_key
  dd_site                    = var.dd_site
  k8s_cluster_ca_certificate = base64decode(data.aws_eks_cluster.app_cluster.certificate_authority[0].data)
  k8s_host                   = data.aws_eks_cluster.app_cluster.endpoint
  k8s_token                  = data.aws_eks_cluster_auth.app_cluster.token
  namespace                  = var.namespace
}
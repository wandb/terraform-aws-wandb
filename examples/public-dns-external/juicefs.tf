module "juicefs" {
  source = "../../modules/juicefs/"

  elasticache_password          = var.elasticache_password
  elasticache_user              = var.elasticache_user
  elasticache_subnet_group_name = module.wandb_infra.elasticache_subnet_group_name
  k8s_cluster_id                = module.wandb_infra.cluster_id
  namespace                     = module.wandb_infra.namespace
  s3_bucket_name                = module.wandb_infra.bucket_name
  security_group_ids            = [module.wandb_infra.elasticache_security_group_ids]
  subnet_ids                    = module.wandb_infra.network_public_subnets
  vpc_id                        = module.wandb_infra.vpc_id
}



variable "elasticache_user" {
  description = "The username used to access Elasticache"
  nullable    = false
  type        = string
}

variable "elasticache_password" {
  description = "Isn't it obvious?"
  nullable    = false
  type        = string
}


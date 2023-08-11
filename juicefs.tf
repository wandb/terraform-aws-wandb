module "juicefs" {
  source = "./modules/juicefs"

  elasticache_password = var.elasticache_password
  elasticache_user = var.elasticache_user
  k8s_cluster_id = module.app_eks.cluster_id
  namespace          = var.namespace
  security_group_ids = [module.redis[0].security_group_id]
  subnet_group_name  = module.redis[0].subnet_group_name
  subnet_ids         = module.networking.private_subnets
  s3_bucket_name     = module.file_storage[0].bucket_name
  vpc_id             = module.networking.vpc_id
}

########################################################
# these don't belong here
########################################################
variable "elasticache_user" {
  description = "The username used to access elasticache"
  nullable    = false
  type        = string
}

variable "elasticache_password" {
  description = "Isn't it obvious?"
  default = "wwsssslslslslslslslslsllslslslslslslslslslslslsls"
  nullable    = false
  type        = string
}
module "juicefs" {
  source = "./modules/juicefs"

  namespace          = var.namespace
  security_group_ids = [module.app_eks.worker_node_security_group_id]
  subnet_group_name  = module.redis[0].subnet_group_name
  subnet_ids         = module.networking.private_subnets
  s3_bucket_name     = module.file_storage[0].bucket_name
  vpc_id             = module.networking.vpc_id
}
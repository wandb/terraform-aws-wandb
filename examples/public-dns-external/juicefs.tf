module "juicefs" {
  depends_on = [module.wandb_infra]
  source     = "../../modules/juicefs"

  namespace          = var.namespace
  security_group_ids = [module.wandb_infra.worker_node_security_group_id]
  subnet_ids         = module.wandb_infra.private_subnet_ids
  s3_bucket_name     = module.wandb_infra.bucket_name
  vpc_id             = module.wandb_infra.vpc_id
}
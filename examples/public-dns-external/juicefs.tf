module "juicefs" {
  source = "../../modules/juicefs"

  namespace          = var.namespace
  security_group_ids = module.wandb_infra.worker_node_security_group_id
  s3_bucket_name     = module.wandb_infra.bucket_name
  vpc_id             = module.wandb_infra.vpc_id
}
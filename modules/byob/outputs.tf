output "bucket_name" {
  value = module.resources.bucket_name
}

output "bucket_kms_key_arn" {
  value = aws_kms_key.key.arn
}

output "wandb_deployment_account_arn" {
  value = local.wandb_deployment_account_arn
}

output "autoscaling_group_names" {
  value = { for name, value in module.eks.node_groups : name => lookup(lookup(lookup(value, "resources")[0], "autoscaling_groups")[0], "name") }
}
output "cluster_name" {
  value       = module.eks.cluster_id
  description = "ID of the created EKS cluster"
}

output "efs_id" {
  value = aws_efs_file_system.storage_class.id
}

output "node_role" {
  value = aws_iam_role.node
}

output "primary_workers_security_group_id" {
  value = aws_security_group.primary_workers.id
}

output "aws_iam_openid_connect_provider" {
  value = aws_iam_openid_connect_provider.eks.url
}

output "weave_worker_auth_secret_name" {
  value       = aws_secretsmanager_secret.weave_worker_auth.name
  description = "Name of the AWS Secrets Manager secret containing the weave worker auth token (used by SecretProviderClass)"
}

output "secrets_store_iam_role_arn" {
  value       = module.secrets_store.iam_role_arn
  description = "ARN of the IAM role for service accounts to access AWS Secrets Manager via CSI driver"
}

output "secrets_store_iam_role_trust_policy" {
  value       = module.secrets_store.iam_role_trust_policy
  description = "Trust policy for the secrets store IAM role - shows which service accounts can assume this role"
}

output "secrets_store_iam_role_permissions_policy" {
  value       = module.secrets_store.iam_role_permissions_policy
  description = "Permissions policy for the secrets store IAM role - shows which secrets can be accessed"
}

output "autoscaling_group_names" {
  value = { for name, value in module.eks.node_groups : name => lookup(lookup(lookup(value, "resources")[0], "autoscaling_groups")[0], "name") }
}
output "cluster_name" {
  value       = module.eks.cluster_id
  description = "ID of the created EKS cluster"
}

# Re-exported for v18+/v20 upgrade parity. Under v20 `module.eks.cluster_name`
# resolves at plan time (statically known), so the docs-page caller pattern
# `data "aws_eks_cluster" { name = module.wandb_infra.cluster_name }` fails
# on a clean first apply with "couldn't find resource". Callers should wire
# the kubernetes/helm providers from these outputs directly. Harmless under
# v17 — community module exposes the same attributes there.
output "cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "Endpoint for the EKS Kubernetes API server"
}

output "cluster_certificate_authority_data" {
  value       = module.eks.cluster_certificate_authority_data
  description = "Base64-encoded CA cert for the EKS cluster"
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

output "autoscaling_group_names" {
  value = module.eks.eks_managed_node_groups_autoscaling_group_names
}
output "cluster_name" {
  value       = module.eks.cluster_name
  description = "Name of the created EKS cluster"
}

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

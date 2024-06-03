output "autoscaling_group_names" {
  value = {
    "primary" = module.eks.eks_managed_node_groups_autoscaling_group_names[0]
  }
}

output "cluster_id" {
  value       = module.eks.cluster_name
  description = "Name of the created EKS cluster"
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

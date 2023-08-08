output "cluster_id" {
  value       = module.eks.cluster_id
  description = "ID of the created EKS cluster"
}

output "autoscaling_group_names" {
  value = { for name, value in module.eks.node_groups : name => lookup(lookup(lookup(value, "resources")[0], "autoscaling_groups")[0], "name") }
}

output "node_role" {
  value = aws_iam_role.node
}

output "worker_node_security_group_id" {
  value = aws_security_group.primary_workers.id
}
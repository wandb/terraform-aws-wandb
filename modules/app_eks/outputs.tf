output "cluster_id" {
  value       = module.eks.cluster_id
  description = "ID of the created EKS cluster"
}

output "node_groups" {
  value = module.eks.node_groups
}

output "autoscaling_group_names" {
  value = { for name, value in module.eks.node_groups : name => lookup(lookup(lookup(value, "resources")[0], "autoscaling_groups")[0], "name") }
}
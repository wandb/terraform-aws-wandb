# State migration for terraform-aws-modules/eks/aws v17 -> v20.
#
# All address renames v17 -> v20 are encoded as `moved {}` blocks here, plus
# one more in `aws_auth_legacy.tf` for the kube-system/aws-auth ConfigMap
# (gated by `var.preserve_aws_auth_configmap`). The v17 worker IAM role/SG
# and the v17-only IAM policies are NOT renamed — v20 doesn't carry forward
# those resources, so they show up in plan as legitimate destroys; the wandb
# data plane uses `aws_iam_role.node` (declared in iam-roles.tf), which is
# a sibling of `module.eks` and therefore unaffected by the destroys.
#
# See docs/upgrade-eks-20.md for the full rationale and the runbook.

# Cluster IAM role: renamed cluster -> this
moved {
  from = module.eks.aws_iam_role.cluster[0]
  to   = module.eks.aws_iam_role.this[0]
}

moved {
  from = module.eks.aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy[0]
  to   = module.eks.aws_iam_role_policy_attachment.this["AmazonEKSClusterPolicy"]
}

# Cluster SG ingress (port 443 from nodes): count -> for_each by key
moved {
  from = module.eks.aws_security_group_rule.cluster_https_worker_ingress[0]
  to   = module.eks.aws_security_group_rule.cluster["ingress_nodes_443"]
}

# Node groups: module.node_groups submodule -> per-key module.eks_managed_node_group.
# Keys follow `ng-${idx}` from `data.aws_subnet.private` in main.tf — adjust
# if the deployment has a different number of private subnets.
moved {
  from = module.eks.module.node_groups.aws_eks_node_group.workers["ng-0"]
  to   = module.eks.module.eks_managed_node_group["ng-0"].aws_eks_node_group.this[0]
}
moved {
  from = module.eks.module.node_groups.aws_launch_template.workers["ng-0"]
  to   = module.eks.module.eks_managed_node_group["ng-0"].aws_launch_template.this[0]
}

moved {
  from = module.eks.module.node_groups.aws_eks_node_group.workers["ng-1"]
  to   = module.eks.module.eks_managed_node_group["ng-1"].aws_eks_node_group.this[0]
}
moved {
  from = module.eks.module.node_groups.aws_launch_template.workers["ng-1"]
  to   = module.eks.module.eks_managed_node_group["ng-1"].aws_launch_template.this[0]
}

moved {
  from = module.eks.module.node_groups.aws_eks_node_group.workers["ng-2"]
  to   = module.eks.module.eks_managed_node_group["ng-2"].aws_eks_node_group.this[0]
}
moved {
  from = module.eks.module.node_groups.aws_launch_template.workers["ng-2"]
  to   = module.eks.module.eks_managed_node_group["ng-2"].aws_launch_template.this[0]
}

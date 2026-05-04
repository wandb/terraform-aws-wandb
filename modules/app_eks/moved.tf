# State migration for terraform-aws-modules/eks/aws v17 -> v20.
#
# Address renames v17 -> v20 are encoded as `moved {}` blocks here, plus
# one more in `aws_auth_legacy.tf` for the kube-system/aws-auth ConfigMap
# (gated by `var.preserve_aws_auth_configmap`). The v17 worker IAM role/SG
# and the v17-only IAM policies are NOT renamed — v20 doesn't carry forward
# those resources, so they show up in plan as legitimate destroys; the wandb
# data plane uses `aws_iam_role.node` (declared in iam-roles.tf), which is
# a sibling of `module.eks` and therefore unaffected by the destroys.
#
# Note: the per-NG `aws_eks_node_group` and `aws_launch_template` move blocks
# do *not* prevent replacement of those resources — v20 hardcodes a
# `"-"` separator between the user-supplied name and the random suffix that
# v17 did not have, so `name_prefix` drifts on a `ForceNew` field. The moves
# still matter: without them v17's NG/LT state would be orphaned at the v17
# address (Terraform destroys the orphan, then creates a fresh resource at
# the v20 address — no `create_before_destroy` linkage between the two
# operations). With the moves, state migrates to the v20 address before the
# replace is planned, so v20's `lifecycle.create_before_destroy = true` on
# both `aws_eks_node_group.this` and `aws_launch_template.this` kicks in:
# new NG/LT is created and healthy before the old one is torn down. See
# docs/upgrade-eks-20.md for the operator runbook.

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
#
# The aws_eks_node_group and aws_launch_template at each new address are
# replaced on the upgrade apply (name_prefix drift; see file header).
# `lifecycle.create_before_destroy = true` in the v20 module makes that
# replacement graceful: capacity stays up, pods drain via PDBs.
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

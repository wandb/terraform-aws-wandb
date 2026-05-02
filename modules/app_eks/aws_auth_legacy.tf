# v17 -> v20 in-place upgrade transition: take ownership of the kube-system/
# aws-auth ConfigMap that the v17 community eks module managed. v20 uses
# EKS access entries instead and no longer declares this resource, so on a
# v17-applied cluster the ConfigMap shows up in state with no matching config
# and TF wants to destroy it (i.e., DELETE it from the cluster) at apply
# time. With `authentication_mode = "API_AND_CONFIG_MAP"`, both auth tables
# coexist, but a delete window during apply can interrupt auth for nodes that
# join, refresh tokens, or open new sessions during the gap.
#
# This file solves that without requiring a manual `terraform state rm`:
#
#   1. The `moved {}` block routes the v17 state entry into a wandb-managed
#      address. Because moved blocks no-op when the source has no state,
#      this is harmless for fresh v20 installs that never had a v17 phase.
#   2. The resource is gated by `var.preserve_aws_auth_configmap`. When
#      true, we adopt the ConfigMap at the new address and rely on
#      `lifecycle.ignore_changes` so TF doesn't try to reconcile cluster
#      contents to whatever is (or isn't) in this resource block.
#   3. Operators flip the variable back to its default (false) once the
#      access-entries auth path is verified, and the next apply cleanly
#      destroys the ConfigMap through the kubernetes provider.

resource "kubernetes_config_map" "aws_auth_legacy" {
  count = var.preserve_aws_auth_configmap ? 1 : 0

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  lifecycle {
    ignore_changes = [data, binary_data]
  }
}

moved {
  from = module.eks.kubernetes_config_map.aws_auth[0]
  to   = kubernetes_config_map.aws_auth_legacy[0]
}

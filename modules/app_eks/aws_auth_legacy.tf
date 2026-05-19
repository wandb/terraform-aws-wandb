# v17 -> v20 in-place upgrade transition: take ownership of the kube-system/
# aws-auth ConfigMap that the v17 community eks module managed changed in v20
# and will result in a deletion with replacement. All this is doing is keeping
# the v17 aws-auth as a resource until we're sure no existing connection
# or token requires it.
# set preserve_aws_auth_configmap to `true` during the v17->v20 upgrade and
# set to `false` a few hours later once access_tokens have cycled
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

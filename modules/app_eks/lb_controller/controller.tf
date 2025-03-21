locals {
  defaultTags = jsonencode(merge({
    "namespace" : var.namespace
    },
  var.aws_loadbalancer_controller_tags))
}

resource "helm_release" "aws_load_balancer_controller" {
  count      = var.enable_aws_loadbalancer_controller ? 1 : 0
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.7.2"

  set {
    name  = "clusterName"
    value = var.namespace
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.default.arn
  }

  values = [
    <<EOT
defaultTags:
  ${local.defaultTags}
EOT
  ]

  depends_on = [aws_iam_role_policy_attachment.default]
}

moved {
  from = helm_release.aws_load_balancer_controller
  to   = helm_release.aws_load_balancer_controller[0]
}

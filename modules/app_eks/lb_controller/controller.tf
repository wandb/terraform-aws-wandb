locals {
  defaultTags = jsonencode(merge({
    "namespace" : var.namespace
    },
  var.aws_loadbalancer_controller_tags))
}

resource "helm_release" "aws_load_balancer_controller" {
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

  set {
    name  = "image.repository"
    value = var.aws_loadbalancer_controller_image
  }

  dynamic "set" {
    for_each = var.aws_loadbalancer_controller_version != null ? [var.aws_loadbalancer_controller_version] : []
    content {
      name = "image.tag"
      value = set.value
    }
  }

  values = [
    <<EOT
defaultTags:
  ${local.defaultTags}
EOT
  ]

  depends_on = [aws_iam_role_policy_attachment.default]
}

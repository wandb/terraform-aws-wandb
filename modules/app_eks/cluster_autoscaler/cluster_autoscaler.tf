data "aws_region" "current" {}

resource "helm_release" "cluster-autoscaler" {
  chart            = "cluster-autoscaler"
  name             = "cluster-autoscaler"
  repository       = "https://kubernetes.github.io/autoscaler"
  namespace        = "cluster-autoscaler"
  create_namespace = true

  set {
    name  = "fullnameOverride"
    value = "cluster-autoscaler"
  }

  set {
    name  = "autoDiscovery.clusterName"
    value = var.namespace
  }

  set {
    name  = "awsRegion"
    value = data.aws_region.current.name
  }

  set {
    name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.default.arn
  }

  set {
    name  = "extraArgs.balance-similar-node-groups"
    value = "true"
  }

  set {
    name  = "extraArgs.balancing-ignore-label"
    value = "eks.amazonaws.com/nodegroup"
  }

  set {
    name  = "extraArgs.balancing-ignore-label"
    value = "eks.amazonaws.com/sourceLaunchTemplateId"
  }

  set {
    name  = "extraArgs.balancing-ignore-label"
    value = "topology.ebs.csi.aws.com/zone"
  }
}
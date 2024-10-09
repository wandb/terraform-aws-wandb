data "aws_region" "current" {}

resource "helm_release" "aws-node-termination-handler" {
  chart = "aws-node-termination-handler"
  name  = "aws-node-termination-handler"
  repository = "https://aws.github.io/eks-charts/"
  namespace = "kube-system"

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
}
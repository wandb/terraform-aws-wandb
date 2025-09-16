terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.4.1"
    }
  }
}




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

  values = [<<EOT
clusterName: ${var.namespace}
serviceAccount:
  name: aws-load-balancer-controller
  annotations:
    eks.amazonaws.com/role-arn: ${aws_iam_role.default.arn}
defaultTags:
  ${local.defaultTags}
EOT
  ]

  depends_on = [aws_iam_role_policy_attachment.default]
}

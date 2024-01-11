#########################################
# OIDC stuff for VPC CNI
#########################################
data "tls_certificate" "vpc_cni" {
  url = module.eks.cluster_oidc_issuer_url
}

resource "aws_eks_addon" "vpc_cni" {
  depends_on   = [
    module.eks,
    aws_iam_openid_connect_provider.eks,
    aws_iam_role_policy_attachment.vpc_cni
  ]

  addon_name   = "vpc-cni"
  addon_version = "v1.13.0-eksbuild.1"
  cluster_name = var.namespace
  preserve = false
  resolve_conflicts = "OVERWRITE"
  service_account_role_arn = aws_iam_role.node.arn
}





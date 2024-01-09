resource "aws_eks_addon" "ebs_csi" {
  addon_name   = "aws-ebs-csi-driver"
  addon_version = "v1.25.0-eksbuild.1"
  cluster_name = var.namespace
  preserve = false
  resolve_conflicts = "OVERWRITE"  
  depends_on = [
    module.eks,
    aws_eks_addon.vpc_cni
  ]
}

resource "aws_eks_addon" "vpc_cni" {
  addon_name   = "vpc-cni"
  addon_version = "v1.13.0-eksbuild.1"
  cluster_name = var.namespace
  preserve = false
  resolve_conflicts = "OVERWRITE"
  service_account_role_arn = aws_iam_role.node.arn
  depends_on   = [
    module.eks,
    aws_iam_openid_connect_provider.eks,
    aws_iam_role_policy_attachment.vpc_cni
  ]
}

#########################################
# OIDC stuff for VPC CNI
#########################################
data "tls_certificate" "vpc_cni" {
  url = module.eks.cluster_oidc_issuer_url
}

#resource "aws_iam_openid_connect_provider" "vpc_cni" {
#  client_id_list  = ["sts.amazonaws.com"]
#  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
#  url             = module.eks.cluster_oidc_issuer_url
#}

resource "aws_iam_role_policy_attachment" "vpc_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}


data "aws_iam_policy_document" "oidc_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role_policy_attachment" "eks-oidc" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.oidc.name
}

resource "aws_iam_role" "oidc" {
  name               = join("-", [var.namespace, "oidc"])
  assume_role_policy = data.aws_iam_policy_document.oidc_assume_role.json
}

# resource "aws_eks_addon" "core-dns" {
#   depends_on = [
#     aws_eks_addon.vpc-cni
#   ]
#   cluster_name                = var.namespace
#   addon_name                  = "coredns"
#   addon_version               = "v1.10.1-eksbuild.4"
#   resolve_conflicts           = "OVERWRITE"
# }

resource "aws_eks_addon" "ebs-csi" {
  depends_on = [
    aws_eks_addon.vpc-cni
  ]
  cluster_name                = var.namespace
  addon_name                  = "aws-ebs-csi-driver"
  addon_version               = "v1.25.0-eksbuild.1"
  resolve_conflicts           = "OVERWRITE"
}

resource "aws_eks_addon" "kube-proxy" {
  depends_on = [
    aws_eks_addon.vpc-cni
  ]
  cluster_name                = var.namespace
  addon_name                  = "kube-proxy"
  addon_version               = "v1.25.14-eksbuild.2"
  resolve_conflicts           = "OVERWRITE"
}

resource "aws_eks_addon" "vpc-cni" {
  cluster_name                = var.namespace
  addon_name                  = "vpc-cni"
  addon_version               = "v1.18.0-eksbuild.1"
  resolve_conflicts           = "OVERWRITE"
}
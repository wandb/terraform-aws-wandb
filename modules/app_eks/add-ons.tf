### IAM policy and role for vpc-cni
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

resource "aws_iam_role_policy_attachment" "eks_oidc" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.oidc.name
}

resource "aws_iam_role" "oidc" {
  name               = join("-", [var.namespace, "oidc"])
  assume_role_policy = data.aws_iam_policy_document.oidc_assume_role.json
}



### add-ons for eks version 1.28

resource "aws_eks_addon" "aws_efs_csi_driver" {
   depends_on = [
     aws_eks_addon.vpc_cni
   ]
   cluster_name               = var.namespace
   addon_name                 = "aws-efs-csi-driver"
   addon_version              = "v2.0.4-eksbuild.1"
   resolve_conflicts          = "OVERWRITE"
}

resource "aws_eks_addon" "aws_ebs_csi_driver" {
  depends_on = [
    aws_eks_addon.vpc_cni
  ]
  cluster_name                = var.namespace
  addon_name                  = "aws-ebs-csi-driver"
  addon_version               = "v1.31.0-eksbuild.1"
  resolve_conflicts           = "OVERWRITE"
}

resource "aws_eks_addon" "coredns" {
  depends_on = [
    aws_eks_addon.vpc_cni
  ]
  cluster_name                = var.namespace
  addon_name                  = "coredns"
  addon_version               = "v1.10.1-eksbuild.11"
  resolve_conflicts           = "OVERWRITE"
}

resource "aws_eks_addon" "kube_proxy" {
  depends_on = [
    aws_eks_addon.vpc_cni
  ]
  cluster_name                = var.namespace
  addon_name                  = "kube-proxy"
  addon_version               = "v1.28.8-eksbuild.5"
  resolve_conflicts           = "OVERWRITE"
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name             = var.namespace
  addon_name               = "vpc-cni"
  addon_version            = "v1.18.2-eksbuild.1"
  resolve_conflicts        = "OVERWRITE"
  service_account_role_arn = aws_iam_role.oidc.arn
}

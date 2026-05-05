### Per-K8s-version default addon versions, sourced from the **def** row of
### eks-addon-compatibility-matrix.md. The matrix omits the `-eksbuild.N`
### suffix; we append `-eksbuild.1` (the most common build). To pin a different
### eksbuild, set the corresponding var.eks_addon_*_version override.
###
### The K8s version used for lookup is var.addons_upgrade_cluster_version when
### set, otherwise var.cluster_version. This lets addon defaults be staged
### ahead of or behind a cluster upgrade.
locals {
  eks_addon_lookup_version = coalesce(var.addons_upgrade_cluster_version, var.cluster_version)

  eks_addon_default_versions = {
    "1.29" = {
      vpc_cni            = "v1.18.5-eksbuild.1"
      coredns            = "v1.11.1-eksbuild.1"
      kube_proxy         = "v1.29.0-eksbuild.1"
      aws_ebs_csi_driver = "v1.28.0-eksbuild.1"
      aws_efs_csi_driver = "v2.0.3-eksbuild.1"
      metrics_server     = "v0.7.2-eksbuild.1"
    }
    "1.30" = {
      vpc_cni            = "v1.18.5-eksbuild.1"
      coredns            = "v1.11.3-eksbuild.1"
      kube_proxy         = "v1.30.0-eksbuild.1"
      aws_ebs_csi_driver = "v1.35.0-eksbuild.1"
      aws_efs_csi_driver = "v2.0.7-eksbuild.1"
      metrics_server     = "v0.7.2-eksbuild.1"
    }
    "1.31" = {
      vpc_cni            = "v1.19.5-eksbuild.1"
      coredns            = "v1.11.3-eksbuild.1"
      kube_proxy         = "v1.31.2-eksbuild.1"
      aws_ebs_csi_driver = "v1.35.0-eksbuild.1"
      aws_efs_csi_driver = "v2.0.7-eksbuild.1"
      metrics_server     = "v0.7.2-eksbuild.1"
    }
    "1.32" = {
      vpc_cni            = "v1.19.5-eksbuild.1"
      coredns            = "v1.11.3-eksbuild.1"
      kube_proxy         = "v1.32.3-eksbuild.1"
      aws_ebs_csi_driver = "v1.42.0-eksbuild.1"
      aws_efs_csi_driver = "v2.0.7-eksbuild.1"
      metrics_server     = "v0.7.2-eksbuild.1"
    }
    "1.33" = {
      vpc_cni            = "v1.20.4-eksbuild.1"
      coredns            = "v1.12.1-eksbuild.1"
      kube_proxy         = "v1.33.0-eksbuild.1"
      aws_ebs_csi_driver = "v1.51.0-eksbuild.1"
      aws_efs_csi_driver = "v2.1.4-eksbuild.1"
      metrics_server     = "v0.7.2-eksbuild.1"
    }
    "1.34" = {
      vpc_cni            = "v1.21.1-eksbuild.1"
      coredns            = "v1.12.4-eksbuild.1"
      kube_proxy         = "v1.34.0-eksbuild.1"
      aws_ebs_csi_driver = "v1.55.0-eksbuild.1"
      aws_efs_csi_driver = "v2.1.6-eksbuild.1"
      metrics_server     = "v0.7.2-eksbuild.1"
    }
    "1.35" = {
      vpc_cni            = "v1.21.1-eksbuild.1"
      coredns            = "v1.13.2-eksbuild.1"
      kube_proxy         = "v1.35.0-eksbuild.1"
      aws_ebs_csi_driver = "v1.57.0-eksbuild.1"
      aws_efs_csi_driver = "v2.1.6-eksbuild.1"
      metrics_server     = "v0.7.2-eksbuild.1"
    }
  }

  eks_addon_versions = {
    vpc_cni            = coalesce(var.eks_addon_vpc_cni_version, local.eks_addon_default_versions[local.eks_addon_lookup_version]["vpc_cni"])
    coredns            = coalesce(var.eks_addon_coredns_version, local.eks_addon_default_versions[local.eks_addon_lookup_version]["coredns"])
    kube_proxy         = coalesce(var.eks_addon_kube_proxy_version, local.eks_addon_default_versions[local.eks_addon_lookup_version]["kube_proxy"])
    aws_ebs_csi_driver = coalesce(var.eks_addon_ebs_csi_driver_version, local.eks_addon_default_versions[local.eks_addon_lookup_version]["aws_ebs_csi_driver"])
    aws_efs_csi_driver = coalesce(var.eks_addon_efs_csi_driver_version, local.eks_addon_default_versions[local.eks_addon_lookup_version]["aws_efs_csi_driver"])
    metrics_server     = coalesce(var.eks_addon_metrics_server_version, local.eks_addon_default_versions[local.eks_addon_lookup_version]["metrics_server"])
  }
}

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

### Addon versions are resolved per cluster version via local.eks_addon_versions
### (see top of file). Each var.eks_addon_*_version overrides the matrix default.
resource "aws_eks_addon" "aws_efs_csi_driver" {
  depends_on = [
    aws_eks_addon.vpc_cni
  ]
  cluster_name      = var.namespace
  addon_name        = "aws-efs-csi-driver"
  addon_version     = local.eks_addon_versions["aws_efs_csi_driver"]
  resolve_conflicts = "OVERWRITE"
}

resource "aws_eks_addon" "aws_ebs_csi_driver" {
  depends_on = [
    aws_eks_addon.vpc_cni
  ]
  cluster_name      = var.namespace
  addon_name        = "aws-ebs-csi-driver"
  addon_version     = local.eks_addon_versions["aws_ebs_csi_driver"]
  resolve_conflicts = "OVERWRITE"
}

resource "aws_eks_addon" "coredns" {
  depends_on = [
    aws_eks_addon.vpc_cni
  ]
  cluster_name      = var.namespace
  addon_name        = "coredns"
  addon_version     = local.eks_addon_versions["coredns"]
  resolve_conflicts = "OVERWRITE"
}

resource "aws_eks_addon" "kube_proxy" {
  depends_on = [
    aws_eks_addon.vpc_cni
  ]
  cluster_name      = var.namespace
  addon_name        = "kube-proxy"
  addon_version     = local.eks_addon_versions["kube_proxy"]
  resolve_conflicts = "OVERWRITE"
}

resource "aws_eks_addon" "vpc_cni" {
  depends_on = [
    module.eks
  ]
  cluster_name             = var.namespace
  addon_name               = "vpc-cni"
  addon_version            = local.eks_addon_versions["vpc_cni"]
  resolve_conflicts        = "OVERWRITE"
  service_account_role_arn = aws_iam_role.oidc.arn
}

resource "aws_eks_addon" "metrics_server" {
  depends_on = [
    module.eks
  ]
  cluster_name      = var.namespace
  addon_name        = "metrics-server"
  addon_version     = local.eks_addon_versions["metrics_server"]
  resolve_conflicts = "OVERWRITE"
}

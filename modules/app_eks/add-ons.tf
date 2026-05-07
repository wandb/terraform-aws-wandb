### Addon version resolution.
###
### Two maps drive defaults:
###
###   local.eks_addon_default_versions
###     Per-K8s-minor map covering ALL addons. Looked up by var.cluster_version.
###     This is the fallback when no preroll target or per-addon override is set.
###
###   local.eks_addons_preroll_versions
###     Sparse, per-K8s-minor map for addons eligible to roll forward AHEAD of a
###     cluster bump. Looked up by var.eks_addons_preroll_version. kube-proxy
###     is intentionally absent (locked to cluster minor by Kubernetes' version
###     skew policy). metrics-server is absent because AWS gates v0.8.x on
###     cluster minor. Maintainers may add/remove entries as AWS evolves.
###
### Resolution order per addon:
###   1. var.eks_addon_<name>_version (explicit per-addon override)
###   2. eks_addons_preroll_versions[<preroll minor>][<addon>] when preroll set
###   3. eks_addon_default_versions[<cluster minor>][<addon>]
locals {
  # Cluster's K8s minor (e.g. "1.30"). Strips an optional patch suffix.
  eks_addon_cluster_minor = regex("^\\d+\\.\\d+", var.cluster_version)

  # K8s minor we are prerolling toward, or null if no preroll is active.
  eks_addon_preroll_minor = var.eks_addons_preroll_version == null ? null : regex("^\\d+\\.\\d+", var.eks_addons_preroll_version)

  # Per-K8s-minor curated defaults. Values are AWS's published defaults at
  # patch time, except 1.30 which mirrors a real customer floor (the minimum
  # supported starting state). 1.29 is intentionally unsupported. Each cell is
  # verified installable on its target minor via describe-addon-versions.
  eks_addon_default_versions = {
    "1.30" = {
      vpc_cni            = "v1.19.3-eksbuild.1"
      coredns            = "v1.11.4-eksbuild.2"
      kube_proxy         = "v1.30.9-eksbuild.3"
      aws_ebs_csi_driver = "v1.40.1-eksbuild.1"
      aws_efs_csi_driver = "v2.1.6-eksbuild.1"
      metrics_server     = "v0.7.2-eksbuild.1"
    }
    "1.31" = {
      vpc_cni            = "v1.20.5-eksbuild.1"
      coredns            = "v1.11.4-eksbuild.33"
      kube_proxy         = "v1.31.14-eksbuild.9"
      aws_ebs_csi_driver = "v1.59.0-eksbuild.1"
      aws_efs_csi_driver = "v3.1.0-eksbuild.1"
      metrics_server     = "v0.8.1-eksbuild.6"
    }
    "1.32" = {
      vpc_cni            = "v1.20.5-eksbuild.1"
      coredns            = "v1.11.4-eksbuild.33"
      kube_proxy         = "v1.32.13-eksbuild.5"
      aws_ebs_csi_driver = "v1.59.0-eksbuild.1"
      aws_efs_csi_driver = "v3.1.0-eksbuild.1"
      metrics_server     = "v0.8.1-eksbuild.6"
    }
    "1.33" = {
      vpc_cni            = "v1.20.5-eksbuild.1"
      coredns            = "v1.12.4-eksbuild.10"
      kube_proxy         = "v1.33.10-eksbuild.2"
      aws_ebs_csi_driver = "v1.59.0-eksbuild.1"
      aws_efs_csi_driver = "v3.1.0-eksbuild.1"
      metrics_server     = "v0.8.1-eksbuild.6"
    }
    "1.34" = {
      vpc_cni            = "v1.20.5-eksbuild.1"
      coredns            = "v1.12.4-eksbuild.10"
      kube_proxy         = "v1.34.6-eksbuild.2"
      aws_ebs_csi_driver = "v1.59.0-eksbuild.1"
      aws_efs_csi_driver = "v3.1.0-eksbuild.1"
      metrics_server     = "v0.8.1-eksbuild.6"
    }
    "1.35" = {
      vpc_cni            = "v1.21.1-eksbuild.1"
      coredns            = "v1.13.2-eksbuild.4"
      kube_proxy         = "v1.35.3-eksbuild.2"
      aws_ebs_csi_driver = "v1.59.0-eksbuild.1"
      aws_efs_csi_driver = "v3.1.0-eksbuild.1"
      metrics_server     = "v0.8.1-eksbuild.6"
    }
  }

  # Sparse: only addons explicitly forward-compatible with the next minor.
  # Key is the K8s minor we are prerolling TO. Each cell must be installable
  # on the cluster's current minor (preroll target - 1). kube-proxy and
  # metrics-server are omitted by design.
  eks_addons_preroll_versions = {
    "1.31" = {
      vpc_cni            = "v1.20.5-eksbuild.1"
      coredns            = "v1.11.4-eksbuild.33"
      aws_ebs_csi_driver = "v1.59.0-eksbuild.1"
      aws_efs_csi_driver = "v3.1.0-eksbuild.1"
    }
    "1.32" = {
      vpc_cni            = "v1.20.5-eksbuild.1"
      coredns            = "v1.11.4-eksbuild.33"
      aws_ebs_csi_driver = "v1.59.0-eksbuild.1"
      aws_efs_csi_driver = "v3.1.0-eksbuild.1"
    }
    "1.33" = {
      vpc_cni            = "v1.20.5-eksbuild.1"
      coredns            = "v1.11.4-eksbuild.33"  # AWS default[1.33].coredns (v1.12.4) is not installable on 1.32; second hop happens at the cluster bump
      aws_ebs_csi_driver = "v1.59.0-eksbuild.1"
      aws_efs_csi_driver = "v3.1.0-eksbuild.1"
    }
    "1.34" = {
      vpc_cni            = "v1.20.5-eksbuild.1"
      coredns            = "v1.12.4-eksbuild.10"
      aws_ebs_csi_driver = "v1.59.0-eksbuild.1"
      aws_efs_csi_driver = "v3.1.0-eksbuild.1"
    }
    "1.35" = {
      vpc_cni            = "v1.21.1-eksbuild.1"
      coredns            = "v1.13.2-eksbuild.4"
      aws_ebs_csi_driver = "v1.59.0-eksbuild.1"
      aws_efs_csi_driver = "v3.1.0-eksbuild.1"
    }
  }

  # Active preroll bucket, or empty if no preroll target set.
  eks_addon_preroll_active = local.eks_addon_preroll_minor == null ? {} : lookup(local.eks_addons_preroll_versions, local.eks_addon_preroll_minor, {})

  eks_addon_versions = {
    vpc_cni = coalesce(
      var.eks_addon_vpc_cni_version,
      lookup(local.eks_addon_preroll_active, "vpc_cni", null),
      local.eks_addon_default_versions[local.eks_addon_cluster_minor]["vpc_cni"]
    )
    coredns = coalesce(
      var.eks_addon_coredns_version,
      lookup(local.eks_addon_preroll_active, "coredns", null),
      local.eks_addon_default_versions[local.eks_addon_cluster_minor]["coredns"]
    )
    kube_proxy = coalesce(
      var.eks_addon_kube_proxy_version,
      lookup(local.eks_addon_preroll_active, "kube_proxy", null),
      local.eks_addon_default_versions[local.eks_addon_cluster_minor]["kube_proxy"]
    )
    aws_ebs_csi_driver = coalesce(
      var.eks_addon_ebs_csi_driver_version,
      lookup(local.eks_addon_preroll_active, "aws_ebs_csi_driver", null),
      local.eks_addon_default_versions[local.eks_addon_cluster_minor]["aws_ebs_csi_driver"]
    )
    aws_efs_csi_driver = coalesce(
      var.eks_addon_efs_csi_driver_version,
      lookup(local.eks_addon_preroll_active, "aws_efs_csi_driver", null),
      local.eks_addon_default_versions[local.eks_addon_cluster_minor]["aws_efs_csi_driver"]
    )
    metrics_server = coalesce(
      var.eks_addon_metrics_server_version,
      lookup(local.eks_addon_preroll_active, "metrics_server", null),
      local.eks_addon_default_versions[local.eks_addon_cluster_minor]["metrics_server"]
    )
  }
}

check "eks_addon_version_key_validation" {
  assert {
    condition     = contains(keys(local.eks_addon_default_versions), local.eks_addon_cluster_minor)
    error_message = <<-EOM
      Invalid EKS cluster version for addon lookup: "${var.cluster_version}" (normalized: "${local.eks_addon_cluster_minor}").

      Supported versions in eks_addon_default_versions: ${join(", ", keys(local.eks_addon_default_versions))}

      Please set var.cluster_version to a supported major.minor version.
    EOM
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
### (see top of file). Each var.eks_addon_*_version overrides the table default.
resource "aws_eks_addon" "aws_efs_csi_driver" {
  depends_on = [
    aws_eks_addon.vpc_cni
  ]
  cluster_name      = var.namespace
  addon_name        = "aws-efs-csi-driver"
  addon_version     = local.eks_addon_versions["aws_efs_csi_driver"]
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_addon" "aws_ebs_csi_driver" {
  depends_on = [
    aws_eks_addon.vpc_cni
  ]
  cluster_name      = var.namespace
  addon_name        = "aws-ebs-csi-driver"
  addon_version     = local.eks_addon_versions["aws_ebs_csi_driver"]
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_addon" "coredns" {
  depends_on = [
    aws_eks_addon.vpc_cni
  ]
  cluster_name      = var.namespace
  addon_name        = "coredns"
  addon_version     = local.eks_addon_versions["coredns"]
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_addon" "kube_proxy" {
  depends_on = [
    aws_eks_addon.vpc_cni
  ]
  cluster_name      = var.namespace
  addon_name        = "kube-proxy"
  addon_version     = local.eks_addon_versions["kube_proxy"]
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_addon" "vpc_cni" {
  depends_on = [
    module.eks
  ]
  cluster_name             = var.namespace
  addon_name               = "vpc-cni"
  addon_version            = local.eks_addon_versions["vpc_cni"]
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  service_account_role_arn = aws_iam_role.oidc.arn
}

resource "aws_eks_addon" "metrics_server" {
  depends_on = [
    module.eks
  ]
  cluster_name      = var.namespace
  addon_name        = "metrics-server"
  addon_version     = local.eks_addon_versions["metrics_server"]
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

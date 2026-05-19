### Addon version resolution.
###
### The data.aws_eks_addon_version data sources query the AWS EKS API for the
### latest addon version compatible with the cluster's Kubernetes minor
### (most_recent = true). This replaces the previously hardcoded version map,
### eliminating the need to update version strings each time AWS publishes a
### new eksbuild.
###
### Default upgrade flow: bump var.cluster_version → terraform apply. The
### data sources automatically resolve the correct addon versions for the new
### cluster minor after the control plane upgrade. No separate addon step is
### needed — AWS's recommended sequence is: control plane, then nodes, then
### addons, and the data sources follow this naturally.
###
### A sparse preroll override map (local.eks_addons_preroll_versions) exists
### as an escape hatch for the rare case where AWS documents that a specific
### addon MUST be at a minimum version before the cluster can be upgraded.
### The map is intentionally empty — it is curated by humans only when a
### hard prerequisite is documented, not as a default step. Most addons
### don't need an entry:
###   - vpc-cni, aws-ebs-csi-driver, aws-efs-csi-driver: forward-compatible;
###     the latest for the current K8s minor continues to work after the
###     upgrade
###   - kube-proxy, metrics-server: locked to the cluster minor; cannot be
###     prerolled (must update after the cluster upgrade)
###   - coredns: forward-compatible in practice; AWS does not require it to
###     be updated before the cluster upgrade
###
### Resolution order per addon:
###   1. var.eks_addon_<name>_version (explicit per-addon override)
###   2. eks_addons_preroll_versions[<preroll minor>][<addon>] when preroll set
###   3. data.aws_eks_addon_version.<addon>.version (AWS API, latest)
###
### Plan drift: the data source is re-read on every terraform plan, so addon
### versions may change between plans when AWS publishes new builds. Use the
### per-addon var overrides to pin a version if deterministic plans are needed.

locals {
  # Cluster's K8s minor (e.g. "1.30"). Strips an optional patch suffix.
  eks_addon_cluster_minor = regex("^\\d+\\.\\d+", var.cluster_version)

  # K8s minor we are prerolling toward, or null if no preroll is active.
  eks_addon_preroll_minor = var.eks_addons_preroll_version == null ? null : regex("^\\d+\\.\\d+", var.eks_addons_preroll_version)

  # Sparse: only addons that require a specific version to be applied BEFORE the
  # EKS cluster upgrade, and where that version differs from what the data source
  # returns for the current cluster version. The map is intentionally empty and is
  # curated by humans only when AWS documents a hard prerequisite.
  #
  # Most addons don't need an entry here:
  #   - vpc-cni, aws-ebs-csi-driver, aws-efs-csi-driver: forward-compatible;
  #     the latest for the current K8s minor continues to work after the upgrade
  #   - kube-proxy, metrics-server: locked to the cluster minor; cannot be
  #     prerolled (must update after the cluster upgrade)
  #   - coredns: forward-compatible in practice; AWS does not require it to be
  #     updated before the cluster upgrade
  #
  # As of EKS 1.30–1.35, no preroll entries are required. Add an entry as
  # { "<target_minor>" = { <addon_key> = "<version>" } } only when AWS documents
  # that a specific addon version must be pinned before the cluster bump.
  eks_addons_preroll_versions = {}

  # Active preroll bucket, or empty if no preroll target set.
  eks_addon_preroll_active = local.eks_addon_preroll_minor == null ? {} : lookup(local.eks_addons_preroll_versions, local.eks_addon_preroll_minor, {})

  eks_addon_versions = {
    vpc_cni = coalesce(
      var.eks_addon_vpc_cni_version,
      lookup(local.eks_addon_preroll_active, "vpc_cni", null),
      data.aws_eks_addon_version.vpc_cni.version,
    )
    coredns = coalesce(
      var.eks_addon_coredns_version,
      lookup(local.eks_addon_preroll_active, "coredns", null),
      data.aws_eks_addon_version.coredns.version,
    )
    kube_proxy = coalesce(
      var.eks_addon_kube_proxy_version,
      lookup(local.eks_addon_preroll_active, "kube_proxy", null),
      data.aws_eks_addon_version.kube_proxy.version,
    )
    aws_ebs_csi_driver = coalesce(
      var.eks_addon_ebs_csi_driver_version,
      lookup(local.eks_addon_preroll_active, "aws_ebs_csi_driver", null),
      data.aws_eks_addon_version.aws_ebs_csi_driver.version,
    )
    aws_efs_csi_driver = coalesce(
      var.eks_addon_efs_csi_driver_version,
      lookup(local.eks_addon_preroll_active, "aws_efs_csi_driver", null),
      data.aws_eks_addon_version.aws_efs_csi_driver.version,
    )
    metrics_server = coalesce(
      var.eks_addon_metrics_server_version,
      lookup(local.eks_addon_preroll_active, "metrics_server", null),
      data.aws_eks_addon_version.metrics_server.version,
    )
  }
}

### Addon version data sources — query AWS for the latest compatible version.
data "aws_eks_addon_version" "vpc_cni" {
  addon_name         = "vpc-cni"
  kubernetes_version = local.eks_addon_cluster_minor
  most_recent        = true
}

data "aws_eks_addon_version" "coredns" {
  addon_name         = "coredns"
  kubernetes_version = local.eks_addon_cluster_minor
  most_recent        = true
}

data "aws_eks_addon_version" "kube_proxy" {
  addon_name         = "kube-proxy"
  kubernetes_version = local.eks_addon_cluster_minor
  most_recent        = true
}

data "aws_eks_addon_version" "aws_ebs_csi_driver" {
  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = local.eks_addon_cluster_minor
  most_recent        = true
}

data "aws_eks_addon_version" "aws_efs_csi_driver" {
  addon_name         = "aws-efs-csi-driver"
  kubernetes_version = local.eks_addon_cluster_minor
  most_recent        = true
}

data "aws_eks_addon_version" "metrics_server" {
  addon_name         = "metrics-server"
  kubernetes_version = local.eks_addon_cluster_minor
  most_recent        = true
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

### Addon versions are resolved via local.eks_addon_versions (see top of file).
### Each var.eks_addon_*_version overrides the data source default.
resource "aws_eks_addon" "aws_efs_csi_driver" {
  depends_on = [
    aws_eks_addon.vpc_cni
  ]
  cluster_name                = var.namespace
  addon_name                  = "aws-efs-csi-driver"
  addon_version               = local.eks_addon_versions["aws_efs_csi_driver"]
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_addon" "aws_ebs_csi_driver" {
  depends_on = [
    aws_eks_addon.vpc_cni
  ]
  cluster_name                = var.namespace
  addon_name                  = "aws-ebs-csi-driver"
  addon_version               = local.eks_addon_versions["aws_ebs_csi_driver"]
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_addon" "coredns" {
  depends_on = [
    aws_eks_addon.vpc_cni
  ]
  cluster_name                = var.namespace
  addon_name                  = "coredns"
  addon_version               = local.eks_addon_versions["coredns"]
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_addon" "kube_proxy" {
  depends_on = [
    aws_eks_addon.vpc_cni
  ]
  cluster_name                = var.namespace
  addon_name                  = "kube-proxy"
  addon_version               = local.eks_addon_versions["kube_proxy"]
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_addon" "vpc_cni" {
  depends_on = [
    module.eks
  ]
  cluster_name                = var.namespace
  addon_name                  = "vpc-cni"
  addon_version               = local.eks_addon_versions["vpc_cni"]
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  service_account_role_arn    = aws_iam_role.oidc.arn
}

resource "aws_eks_addon" "metrics_server" {
  depends_on = [
    module.eks
  ]
  cluster_name                = var.namespace
  addon_name                  = "metrics-server"
  addon_version               = local.eks_addon_versions["metrics_server"]
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

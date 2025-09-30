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

### add-ons for eks version 1.30
resource "aws_eks_addon" "aws_efs_csi_driver" {
  depends_on = [
    aws_eks_addon.vpc_cni
  ]
  cluster_name      = var.namespace
  addon_name        = "aws-efs-csi-driver"
  addon_version     = var.eks_addon_efs_csi_driver_version
  resolve_conflicts = "OVERWRITE"
}

resource "aws_eks_addon" "aws_ebs_csi_driver" {
  depends_on = [
    aws_eks_addon.vpc_cni
  ]
  cluster_name      = var.namespace
  addon_name        = "aws-ebs-csi-driver"
  addon_version     = var.eks_addon_ebs_csi_driver_version
  resolve_conflicts = "OVERWRITE"
}

resource "aws_eks_addon" "coredns" {
  depends_on = [
    aws_eks_addon.vpc_cni
  ]
  cluster_name      = var.namespace
  addon_name        = "coredns"
  addon_version     = var.eks_addon_coredns_version
  resolve_conflicts = "OVERWRITE"
}

resource "aws_eks_addon" "kube_proxy" {
  depends_on = [
    aws_eks_addon.vpc_cni
  ]
  cluster_name      = var.namespace
  addon_name        = "kube-proxy"
  addon_version     = var.eks_addon_kube_proxy_version
  resolve_conflicts = "OVERWRITE"
}

resource "aws_eks_addon" "vpc_cni" {
  depends_on = [
    module.eks
  ]
  cluster_name             = var.namespace
  addon_name               = "vpc-cni"
  addon_version            = var.eks_addon_vpc_cni_version
  resolve_conflicts        = "OVERWRITE"
  service_account_role_arn = aws_iam_role.oidc.arn

  configuration_values = jsonencode({
    env = {
      AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG = length(var.network_pod_subnets) > 0 ? "true" : "false"
      ENI_CONFIG_LABEL_DEF = "topology.kubernetes.io/zone"
    }
  })
}

data "aws_subnet" "pod_subnets" {
  count = length(var.network_pod_subnets)
  id    = var.network_pod_subnets[count.index]
}

resource "kubectl_manifest" "vpc_eni_config" {
  count = length(data.aws_subnet.pod_subnets)

  yaml_body = <<YAML
apiVersion: crd.k8s.amazonaws.com/v1alpha1
kind: ENIConfig
metadata:
  name: ${data.aws_subnet.pod_subnets[count.index].availability_zone}
spec:
  subnet: ${data.aws_subnet.pod_subnets[count.index].id}
  securityGroups:
    - ${module.eks.worker_security_group_id}
    - ${aws_security_group.pods.id}
YAML

  depends_on = [
    aws_eks_addon.vpc_cni
  ]
}

resource "aws_eks_addon" "metrics_server" {
  depends_on = [
    module.eks
  ]
  cluster_name      = var.namespace
  addon_name        = "metrics-server"
  addon_version     = var.eks_addon_metrics_server_version
  resolve_conflicts = "OVERWRITE"
}

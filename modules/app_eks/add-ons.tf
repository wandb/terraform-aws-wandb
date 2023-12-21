resource "aws_eks_addon" "ebs-csi" {
  cluster_name      = var.namespace
  addon_name        = "aws-ebs-csi-driver"
  addon_version     = "v1.25.0-eksbuild.1"
  resolve_conflicts = "OVERWRITE"
 
}

resource "aws_eks_addon" "vpc-cni" {
  cluster_name      = var.namespace
  addon_name        = "vpc-cni"
  addon_version     = "v1.13.4-eksbuild.1"  
  resolve_conflicts = "OVERWRITE"
}



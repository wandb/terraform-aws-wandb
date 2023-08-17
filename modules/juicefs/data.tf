data "aws_iam_access_keys" "juicefs" {
  user = aws_iam_user.juicefs.name
}

data "aws_s3_bucket" "juicefs" {
  bucket = var.s3_bucket_name
}

data "aws_eks_cluster" "wandb" {
  name = var.k8s_cluster_id
}

data "aws_eks_cluster_auth" "wandb" {
  name = var.k8s_cluster_id
}

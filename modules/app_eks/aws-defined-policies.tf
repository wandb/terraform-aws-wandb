data "aws_iam_policy" "eks_worker_node" {
    arn =  "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

data "aws_iam_policy" "eks_cni" {
    arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

data "aws_iam_policy" "ec2_container_registry" {
    arn =   "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
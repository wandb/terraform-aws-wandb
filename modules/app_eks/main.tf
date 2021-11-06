locals {
  arn_cluster_policy = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  arn_service_policy = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}
resource "aws_security_group" "ingress" {
  name        = "${var.namespace}-eks-master"
  description = "Cluster communication with worker nodes"
  vpc_id      = var.network_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.namespace}-eks-master"
  }
}

# resource "aws_iam_role" "cluster" {
#   name = "${var.namespace}-cluster"

#   assume_role_policy = jsonencode({
#     "Version" : "2012-10-17",
#     "Statement" : [
#       {
#         "Effect" : "Allow",
#         "Principal" : {
#           "Service" : "eks.amazonaws.com"
#         },
#         "Action" : "sts:AssumeRole"
#       }
#     ]
#   })

#   managed_policy_arns = [
#     local.arn_cluster_policy,
#     local.arn_service_policy
#   ]
# }

data "aws_iam_policy_document" "node" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# # Create cluster on VPC network
# resource "aws_eks_cluster" "default" {
#   name     = var.namespace
#   role_arn = aws_iam_role.cluster.arn
#   version  = "1.21"

#   vpc_config {
#     endpoint_private_access = true
#     endpoint_public_access  = true
#     security_group_ids      = [aws_security_group.this.id]
#     subnet_ids              = var.network_private_subnets
#   }

#   depends_on = [aws_iam_role.cluster]
# }

# # Configure permissions required for nodes
resource "aws_iam_role" "node" {
  name               = "${var.namespace}-node"
  assume_role_policy = data.aws_iam_policy_document.node.json

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]

  # Policy to access S3
  inline_policy {
    name = "${var.namespace}-node-s3-policy"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : "s3:*",
          "Resource" : [
            "${var.bucket_arn}",
            "${var.bucket_arn}/*"
          ]
        }
      ]
    })
  }

  # Policy to access SQS
  inline_policy {
    name = "${var.namespace}-node-sqs-policy"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : "sqs:*",
          "Resource" : [
            "${var.bucket_sqs_queue_arn}"
          ]
        }
      ]
    })
  }
}

# # Create worker pool with permission to access S3 and SQS
# resource "aws_eks_node_group" "primary" {
#   cluster_name    = aws_eks_cluster.default.name
#   node_group_name = "${var.namespace}-node-group"
#   node_role_arn   = aws_iam_role.node.arn
#   subnet_ids      = var.network_private_subnets

#   scaling_config {
#     desired_size = 1
#     max_size     = 2
#     min_size     = 1
#   }

#   instance_types = ["m5.xlarge"]

#   # Ensure that IAM Role permissions are created before and deleted after EKS
#   # Node Group handling. Otherwise, EKS will not be able to properly delete EC2
#   # Instances and Elastic Network Interfaces.
#   depends_on = [
#     aws_eks_cluster.default,
#     aws_iam_role.node
#   ]
# }

locals {
  cluster_version = "1.20"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 17.23"

  cluster_name    = var.namespace
  cluster_version = local.cluster_version

  vpc_id  = var.network_id
  subnets = var.network_private_subnets

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  # cluster_encryption_config = [
  #   {
  #     provider_key_arn = var.kms_key_arn
  #     resources        = ["secrets"]
  #   }
  # ]

  # worker_groups = [
  #   {
  #     name                 = "worker-group-1"
  #     instance_type        = "t3.small"
  #     asg_desired_capacity = 2
  #   },
  # ]

  # default_iam_role_arn = aws_iam_role.node.arn

  node_groups = {
    primary = {
      desired_capacity = 1,
      max_capacity     = 1,
      min_capacity     = 1,
      instance_type    = ["m5.xlarge"],
      iam_role_arn     = aws_iam_role.node.arn
    }
  }

  tags = {
    GithubRepo         = "wandb"
    GithubOrg          = "terraform-aws-wandb"
    TerraformNamespace = var.namespace
    TerraformModule    = "terraform-aws-wandb/module/app_eks"
  }
}

resource "aws_security_group_rule" "ingress" {
  description              = "Allow comntainer NodePort service to receive load balancer traffic."
  protocol                 = "tcp"
  security_group_id        = module.eks.cluster_primary_security_group_id
  source_security_group_id = var.security_group_inbound_id
  from_port                = 32543
  to_port                  = 32543
  type                     = "ingress"
}
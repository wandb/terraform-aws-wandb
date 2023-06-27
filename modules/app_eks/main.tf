locals {
  mysql_port         = 3306
  redis_port         = 6379
  encrypt_ebs_volume = true
}

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

resource "aws_eks_addon" "eks" {
  cluster_name = var.namespace
  addon_name   = "aws-ebs-csi-driver"
  depends_on = [
    module.eks
  ]
}

locals {
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  ]
}

# Configure permissions required for nodes
resource "aws_iam_role" "node" {
  name               = "${var.namespace}-node"
  assume_role_policy = data.aws_iam_policy_document.node.json

  managed_policy_arns = local.managed_policy_arns

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

  # Policy to access SQS. If we are using an internal queue, we dont need to set
  # any permissions
  dynamic "inline_policy" {
    for_each = var.bucket_sqs_queue_arn == null ? [] : [1]
    content {
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

  # Encrypt and decrypt with KMS
  dynamic "inline_policy" {
    for_each = var.bucket_kms_key_arn == "" ? [] : [1]
    content {
      name = "${var.namespace}-node-kms-policy"
      policy = jsonencode({
        "Version" : "2012-10-17",
        "Statement" : [
          {
            "Effect" : "Allow",
            "Action" : [
              "kms:Encrypt",
              "kms:Decrypt",
              "kms:ReEncrypt*",
              "kms:GenerateDataKey*",
              "kms:DescribeKey"
            ],
            "Resource" : [
              "${var.bucket_kms_key_arn}"
            ]
          }
        ]
      })
    }
  }

  # Publish cloudwatch metrics
  inline_policy {
    name = "${var.namespace}-node-cloudwatch-policy"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : ["cloudwatch:PutMetricData"],
          "Resource" : "*"
        }
      ]
    })
  }

  # Enable IMDsv2 
  inline_policy {
    name = "${var.namespace}-node-IMDsv2-policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = "ec2:DescribeInstanceAttribute"
          Resource = "*"
        },
        {
          Effect   = "Allow"
          Action   = "ec2:PutInstanceMetadata"
          Resource = "*"
        }
      ]
    })
  }
}

resource "aws_iam_role_policy_attachment" "node" {
  for_each   = var.eks_policy_arns
  role       = aws_iam_role.node.name
  policy_arn = each.value
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 17.23"

  cluster_name    = var.namespace
  cluster_version = var.cluster_version

  vpc_id  = var.network_id
  subnets = var.network_private_subnets

  map_accounts = var.map_accounts
  map_roles    = var.map_roles
  map_users    = var.map_users

  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  cluster_encryption_config = var.kms_key_arn != "" ? [
    {
      provider_key_arn = var.kms_key_arn
      resources        = ["secrets"]
    }
  ] : null

  worker_additional_security_group_ids = [aws_security_group.primary_workers.id]

  node_groups = {
    primary = {
      version                = var.cluster_version,
      desired_capacity       = 2,
      max_capacity           = 5,
      min_capacity           = 2,
      instance_types         = var.instance_types,
      iam_role_arn           = aws_iam_role.node.arn,
      create_launch_template = local.encrypt_ebs_volume,
      disk_encrypted         = local.encrypt_ebs_volume,
      disk_kms_key_id        = var.kms_key_arn,
      force_update_version   = local.encrypt_ebs_volume,
      # IMDsv2
      metadata_http_tokens                 = "required",
      metadata_http_put_response_hop_limit = 2
    }
  }

  tags = {
    GithubRepo         = "wandb"
    GithubOrg          = "terraform-aws-wandb"
    TerraformNamespace = var.namespace
    TerraformModule    = "terraform-aws-wandb/module/app_eks"
  }
}

resource "aws_security_group" "primary_workers" {
  name        = "${var.namespace}-primary-workers"
  description = "EKS primary workers security group."
  vpc_id      = var.network_id
}

resource "aws_security_group_rule" "lb" {
  description              = "Allow container NodePort service to receive load balancer traffic."
  protocol                 = "tcp"
  security_group_id        = aws_security_group.primary_workers.id
  source_security_group_id = var.lb_security_group_inbound_id
  from_port                = var.service_port
  to_port                  = var.service_port
  type                     = "ingress"
}

resource "aws_security_group_rule" "database" {
  description              = "Allow inbound traffic from EKS workers to database"
  protocol                 = "tcp"
  security_group_id        = var.database_security_group_id
  source_security_group_id = aws_security_group.primary_workers.id
  from_port                = local.mysql_port
  to_port                  = local.mysql_port
  type                     = "ingress"
}

resource "aws_security_group_rule" "elasticache" {
  count                    = var.create_elasticache_security_group ? 1 : 0
  description              = "Allow inbound traffic from EKS workers to elasticache"
  protocol                 = "tcp"
  security_group_id        = var.elasticache_security_group_id
  source_security_group_id = aws_security_group.primary_workers.id
  from_port                = local.redis_port
  to_port                  = local.redis_port
  type                     = "ingress"
}

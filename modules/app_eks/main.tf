data "aws_caller_identity" "current" {}

locals {
  mysql_port         = 3306
  redis_port         = 6379
  encrypt_ebs_volume = true
  system_reserved = join(",", flatten([
    var.system_reserved_cpu_millicores >= 0 ? ["cpu=${var.system_reserved_cpu_millicores}m"] : [],
    var.system_reserved_memory_megabytes >= 0 ? ["memory=${var.system_reserved_memory_megabytes}Mi"] : [],
    var.system_reserved_ephemeral_megabytes >= 0 ? ["ephemeral-storage=${var.system_reserved_ephemeral_megabytes}Mi"] : [],
    var.system_reserved_pid >= 0 ? ["pid=${var.system_reserved_pid}"] : []
  ]))
  create_launch_template = (local.encrypt_ebs_volume || local.system_reserved != "")
  defaultTags            = var.aws_loadbalancer_controller_tags
  cluster_tags           = var.cluster_tags
}


data "aws_subnet" "private" {
  count = length(var.network_private_subnets)
  id    = var.network_private_subnets[count.index]
}

module "eks" {
  # Vendored fork of terraform-aws-modules/eks/aws ~> 20.37, patched to add
  # a `name_prefix_separator` variable on the eks-managed-node-group submodule
  # so v17 -> v20 in-place upgrades can preserve the existing v17-era
  # node_group_name_prefix / launch_template name_prefix (which had no trailing
  # separator). See docs/upgrade-eks-20.md and vendored/terraform-aws-eks-v20/.
  source = "../../vendored/terraform-aws-eks-v20"

  cluster_name    = var.namespace
  cluster_version = var.cluster_version

  # Pinned for v18+/v20 upgrade parity. The wandb-side
  # aws_iam_openid_connect_provider.eks (below) is the sole manager of the
  # cluster's OIDC URL; v20 flipped this default to true, which causes a 409
  # EntityAlreadyExists when both layers race to create the same OIDC
  # provider. No-op under v17 where the default is already false.
  enable_irsa = false

  # v17 -> v20 in-place upgrade compatibility:
  # v17 created the cluster IAM role and SG with name_prefix = var.cluster_name
  # (no separator). v20 default would produce "${cluster_name}-cluster-",
  # which TF sees as a different resource and forces destroy/recreate of the
  # role -> changes role_arn -> forces cluster replacement. Overriding the
  # name and dropping the prefix separator keeps the same name_prefix in state
  # so TF treats the existing AWS resources as still-managed.
  iam_role_name                          = var.namespace
  iam_role_use_name_prefix               = true
  cluster_security_group_name            = var.namespace
  cluster_security_group_use_name_prefix = true
  cluster_security_group_description     = "EKS cluster security group." # v17 trailing period; SG description is immutable in AWS
  prefix_separator                       = ""

  vpc_id     = var.network_id
  subnet_ids = var.network_private_subnets

  authentication_mode                      = "API_AND_CONFIG_MAP"
  enable_cluster_creator_admin_permissions = true
  access_entries = merge(
    {
      for r in var.map_roles : r.username => {
        principal_arn       = r.rolearn
        kubernetes_groups   = r.groups
        policy_associations = {}
      }
    },
    {
      for u in var.map_users : u.username => {
        principal_arn       = u.userarn
        kubernetes_groups   = u.groups
        policy_associations = {}
      }
    }
  )

  cluster_enabled_log_types              = ["api", "audit", "controllerManager", "scheduler"]
  cluster_endpoint_private_access        = true
  cluster_endpoint_public_access         = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs   = var.cluster_endpoint_public_access_cidrs
  cloudwatch_log_group_retention_in_days = 30

  create_kms_key = false
  # Type-unifier-safe conditional: object vs {} can't share a ternary directly
  # ("Inconsistent conditional result types"). Round-tripping through JSON makes
  # both branches `string` at the ternary and `any` at the module input, while
  # preserving the runtime shape v20 gates on via
  # enable_cluster_encryption_config = length(var.cluster_encryption_config) > 0
  # (length 2 with KMS, length 0 without). See docs/upgrade-eks-20.md.
  cluster_encryption_config = jsondecode(var.kms_key_arn != "" ? jsonencode({
    provider_key_arn = var.kms_key_arn
    resources        = ["secrets"]
  }) : "{}")

  node_security_group_additional_rules = {
    primary_workers_all = {
      description              = "Allow traffic from primary_workers security group"
      protocol                 = "-1"
      from_port                = 0
      to_port                  = 0
      type                     = "ingress"
      source_security_group_id = aws_security_group.primary_workers.id
    }
  }

  eks_managed_node_group_defaults = {
    create_launch_template = local.create_launch_template
    create_iam_role        = false
    iam_role_arn           = aws_iam_role.node.arn
    instance_types         = var.instance_types
    enable_monitoring      = true
    force_update_version   = local.encrypt_ebs_volume
    cluster_version        = var.cluster_version
    bootstrap_extra_args   = local.system_reserved != "" ? "--kubelet-extra-args '--system-reserved=${local.system_reserved}'" : ""

    # v17 -> v20 in-place upgrade: v17's launch_template / node_group used
    # name_prefix = "<namespace>-<az>" (no trailing separator). v20 stock hardcodes
    # "${name}-". Vendored submodule exposes `name_prefix_separator` for this; "".
    name_prefix_separator = ""

    metadata_options = {
      http_put_response_hop_limit = 2
      http_tokens                 = "required"
    }

    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size = var.disk_size
          volume_type = "gp3"
          encrypted   = local.encrypt_ebs_volume
          kms_key_id  = var.kms_key_arn != "" ? var.kms_key_arn : null
        }
      }
    }
  }

  eks_managed_node_groups = {
    for idx, subnet in data.aws_subnet.private : "ng-${idx}" => {
      subnet_ids      = [subnet.id]
      name            = "${var.namespace}-${regex(".*[[:digit:]]([[:alpha:]])", subnet.availability_zone)[0]}"
      use_name_prefix = true
      # Parent module defaults launch_template_name to each.key ("ng-0") if
      # unset; explicitly pin it to match var.name so the v17 launch_template
      # name_prefix ("<namespace>-<az>") is preserved on upgrade.
      launch_template_name   = "${var.namespace}-${regex(".*[[:digit:]]([[:alpha:]])", subnet.availability_zone)[0]}"
      desired_size           = var.min_nodes
      max_size               = var.max_nodes
      min_size               = var.min_nodes
      vpc_security_group_ids = [aws_security_group.primary_workers.id]
    }
  }

  tags = merge(local.defaultTags, {
    GithubRepo         = "wandb"
    GithubOrg          = "terraform-aws-wandb"
    TerraformNamespace = var.namespace
    TerraformModule    = "terraform-aws-wandb/module/app_eks"
  })

  cluster_tags = local.cluster_tags
}

resource "kubernetes_annotations" "gp2" {
  api_version = "storage.k8s.io/v1"
  kind        = "StorageClass"
  force       = "true"
  depends_on  = [module.eks]

  metadata {
    name = "gp2"
  }
  annotations = {
    "storageclass.kubernetes.io/is-default-class" = "false"
  }
}

resource "kubernetes_storage_class" "gp3" {
  metadata {
    name = "gp3"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  depends_on          = [kubernetes_annotations.gp2]
  storage_provisioner = "kubernetes.io/aws-ebs"
  parameters = {
    fsType = "ext4"
    type   = "gp3"
  }
  reclaim_policy         = "Delete"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true
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

data "tls_certificate" "eks" {
  url = module.eks.cluster_oidc_issuer_url
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = module.eks.cluster_oidc_issuer_url
}

module "lb_controller" {
  source = "./lb_controller"

  namespace                                    = var.namespace
  oidc_provider                                = aws_iam_openid_connect_provider.eks
  aws_loadbalancer_controller_tags             = var.aws_loadbalancer_controller_tags
  aws_loadbalancer_controller_image_repository = var.aws_loadbalancer_controller_image_repository
  aws_loadbalancer_controller_image_tag        = var.aws_loadbalancer_controller_image_tag

  depends_on = [module.eks]
}

module "external_dns" {
  source = "./external_dns"

  namespace                     = var.namespace
  oidc_provider                 = aws_iam_openid_connect_provider.eks
  fqdn                          = var.fqdn
  external_dns_image_repository = var.external_dns_image_repository
  external_dns_image_tag        = var.external_dns_image_tag

  depends_on = [
    module.eks,
    module.lb_controller
  ]
}

module "cluster_autoscaler" {
  source = "./cluster_autoscaler"

  namespace                           = var.namespace
  oidc_provider                       = aws_iam_openid_connect_provider.eks
  cluster_autoscaler_image_repository = var.cluster_autoscaler_image_repository
  cluster_autoscaler_image_tag        = var.cluster_autoscaler_image_tag
  depends_on = [
    module.eks,
    module.lb_controller
  ]
}

# Weave worker authentication token
resource "random_password" "weave_worker_auth" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "weave_worker_auth" {
  name                    = "${var.namespace}-weave-worker-auth"
  recovery_window_in_days = 0

  tags = {
    TerraformNamespace = var.namespace
    TerraformModule    = "terraform-aws-wandb/module/app_eks"
  }
}

resource "aws_secretsmanager_secret_version" "weave_worker_auth" {
  secret_id     = aws_secretsmanager_secret.weave_worker_auth.id
  secret_string = random_password.weave_worker_auth.result
}

# IAM policy to allow reading the secret
resource "aws_iam_policy" "weave_worker_auth_secret_reader" {
  name        = "${var.namespace}-weave-worker-auth-secret-reader"
  description = "Allow reading weave worker auth secret from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.weave_worker_auth.arn
      }
    ]
  })
}

# Attach the policy to the node role
resource "aws_iam_role_policy_attachment" "weave_worker_auth_secret_reader" {
  role       = aws_iam_role.node.name
  policy_arn = aws_iam_policy.weave_worker_auth_secret_reader.arn
}

# Create Kubernetes secret with the token
resource "kubernetes_secret" "weave_worker_auth" {
  metadata {
    name      = "weave-worker-auth"
    namespace = var.k8s_namespace
  }

  binary_data = {
    "key" = random_password.weave_worker_auth.result
  }

  depends_on = [module.eks]
}

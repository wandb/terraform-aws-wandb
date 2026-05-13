variable "bucket_arn" {
  type     = string
  nullable = false
}

variable "bucket_kms_key_arns" {
  description = "The Amazon Resource Name of the KMS key with which S3 storage bucket objects will be encrypted."
  type        = list(string)
}

variable "map_bucket_permissions" {
  description = "A Map of the parent modules 'bucket_permissions_mode' & 'bucket_restricted_accounts' variables"
  type = object({
    mode     = string,
    accounts = list(string)
  })
  default = {
    mode     = "strict",
    accounts = []
  }
}

variable "fqdn" {
  type = string
}

variable "bucket_sqs_queue_arn" {
  default = ""
  type    = string
}

variable "cluster_endpoint_public_access" {
  type        = bool
  description = "(Optional) Indicates whether or not the Amazon EKS public API server endpoint is enabled."
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint."
  type        = list(string)
  default     = []
}

variable "cluster_version" {
  description = "Indicates AWS EKS cluster version"
  nullable    = false
  type        = string

  validation {
    condition = can(regex("^[0-9]+\\.[0-9]+(\\.[0-9]+)?$", var.cluster_version)) && contains(
      keys(local.eks_addon_default_versions),
      format("%s.%s", split(".", var.cluster_version)[0], split(".", var.cluster_version)[1])
    )
    error_message = "cluster_version must be a supported EKS Kubernetes version (major.minor or major.minor.patch). Supported: ${join(", ", sort(keys(local.eks_addon_default_versions)))}. Got: '${var.cluster_version}'."
  }
}

variable "eks_addons_preroll_version" {
  description = "Optional Kubernetes minor version to roll preroll-eligible addons toward, while the cluster itself stays on var.cluster_version. Looked up against local.eks_addons_preroll_versions in modules/app_eks/add-ons.tf. kube-proxy and metrics-server are intentionally excluded from preroll. When null, no preroll is active."
  type        = string
  default     = null

  validation {
    condition = var.eks_addons_preroll_version == null || (
      can(regex("^[0-9]+\\.[0-9]+(\\.[0-9]+)?$", coalesce(var.eks_addons_preroll_version, "0.0"))) && contains(
        keys(local.eks_addons_preroll_versions),
        format("%s.%s",
          split(".", coalesce(var.eks_addons_preroll_version, "0.0"))[0],
          split(".", coalesce(var.eks_addons_preroll_version, "0.0"))[1]
        )
      )
    )
    error_message = "eks_addons_preroll_version must be null or a Kubernetes minor present in local.eks_addons_preroll_versions. Supported: ${join(", ", sort(keys(local.eks_addons_preroll_versions)))}. Got: '${coalesce(var.eks_addons_preroll_version, "null")}'."
  }

  # Compare as (major * 1000 + minor) so e.g. "1.10" > "1.9". Skip when null.
  validation {
    condition = var.eks_addons_preroll_version == null || (
      tonumber(split(".", coalesce(var.eks_addons_preroll_version, "0.0"))[0]) * 1000
      + tonumber(split(".", coalesce(var.eks_addons_preroll_version, "0.0"))[1])
      >=
      tonumber(split(".", var.cluster_version)[0]) * 1000
      + tonumber(split(".", var.cluster_version)[1])
    )
    error_message = "eks_addons_preroll_version must be >= cluster_version (cannot stage addons for an older Kubernetes version)."
  }
}

variable "cluster_tags" {
  description = "A map of AWS tags to apply to all resources managed by the EKS cluster"
  type        = map(string)
  default     = {}
}

variable "create_elasticache_security_group" {
  type    = bool
  default = false
}

variable "database_security_group_id" {
  type = string
}

variable "eks_policy_arns" {
  description = "Additional IAM policy to apply to the EKS cluster"
  type        = list(string)
  default     = []
}

variable "elasticache_security_group_id" {
  type    = string
  default = null
}

variable "kms_key_arn" {
  description = "(Required) The Amazon Resource Name of the KMS key with which EKS secrets will be encrypted."
  type        = string
}

variable "instance_types" {
  description = "EC2 Instance type for primary node group."
  nullable    = false
  type        = list(string)
}

variable "disk_size" {
  description = "The size of the EBS volume in GiB for the root block device of node group instances."
  nullable    = false
  type        = number
  default     = 100
}

variable "lb_security_group_inbound_id" {
  type = string
}

variable "map_accounts" {
  description = "REMOVED. AWS account numbers for the aws-auth ConfigMap. EKS module v20 uses access entries, which require a per-principal ARN — account-wide trust is no longer expressible. See docs/upgrade-eks-20.md for migration paths. The variable is retained as a tripwire and will be removed in a future release."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.map_accounts) == 0
    error_message = "map_accounts is no longer supported. Enumerate the specific roles or users into map_roles / map_users (which now flow into access_entries), or — if you truly need account-wide trust — manage the aws-auth ConfigMap directly with a kubernetes_config_map_v1_data resource. See docs/upgrade-eks-20.md (Dropped variables) for details."
  }
}

variable "map_roles" {
  description = "Additional IAM roles to add to the aws-auth configmap. See examples/basic/variables.tf for example format."
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "map_users" {
  description = "Additional IAM users to add to the aws-auth configmap. See examples/basic/variables.tf for example format."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "namespace" {
  type        = string
  description = "(Required) The name prefix for all resources created."
}

variable "k8s_namespace" {
  type        = string
  description = "The Kubernetes namespace where W&B resources will be deployed"
  default     = "default"
}

variable "network_id" {
  description = "(Required) The identity of the VPC in which the security group attached to the MySQL Aurora instances will be deployed."
  type        = string
}

variable "network_private_subnets" {
  description = "(Required) A list of the identities of the private subnetworks in which the MySQL Aurora instances will be deployed."
  type        = list(string)
}

variable "service_port" {
  type    = number
  default = 32543
}

variable "min_nodes" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 2
}

variable "max_nodes" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 2
}

variable "system_reserved_cpu_millicores" {
  description = "(Optional) The amount of 'system-reserved' CPU millicores to pass to the kubelet. For example: 100.  A value of -1 disables the flag."
  type        = number
  default     = -1
}

variable "system_reserved_memory_megabytes" {
  description = "(Optional) The amount of 'system-reserved' memory in megabytes to pass to the kubelet. For example: 100.  A value of -1 disables the flag."
  type        = number
  default     = -1
}

variable "system_reserved_ephemeral_megabytes" {
  description = "(Optional) The amount of 'system-reserved' ephemeral storage in megabytes to pass to the kubelet. For example: 1000.  A value of -1 disables the flag."
  type        = number
  default     = -1
}

variable "system_reserved_pid" {
  description = "(Optional) The amount of 'system-reserved' process ids [pid] to pass to the kubelet. For example: 1000.  A value of -1 disables the flag."
  type        = number
  default     = -1
}

variable "aws_loadbalancer_controller_tags" {
  description = "(Optional) A map of AWS tags to apply to all resources managed by the load balancer controller"
  type        = map(string)
  default     = {}
}

variable "eks_addon_efs_csi_driver_version" {
  description = "Override for the EFS CSI driver version. When null, the version is resolved via local.eks_addon_versions in modules/app_eks/add-ons.tf (default lookup by var.cluster_version, with optional preroll override via var.eks_addons_preroll_version for preroll-eligible addons)."
  type        = string
  default     = null
}

variable "eks_addon_ebs_csi_driver_version" {
  description = "Override for the EBS CSI driver version. When null, the version is resolved via local.eks_addon_versions in modules/app_eks/add-ons.tf (default lookup by var.cluster_version, with optional preroll override via var.eks_addons_preroll_version for preroll-eligible addons)."
  type        = string
  default     = null
}

variable "eks_addon_coredns_version" {
  description = "Override for the CoreDNS addon version. When null, the version is resolved via local.eks_addon_versions in modules/app_eks/add-ons.tf (default lookup by var.cluster_version, with optional preroll override via var.eks_addons_preroll_version for preroll-eligible addons)."
  type        = string
  default     = null
}

variable "eks_addon_kube_proxy_version" {
  description = "Override for the kube-proxy addon version. When null, the version is resolved via local.eks_addon_versions in modules/app_eks/add-ons.tf (default lookup by var.cluster_version, with optional preroll override via var.eks_addons_preroll_version for preroll-eligible addons)."
  type        = string
  default     = null
}

variable "eks_addon_vpc_cni_version" {
  description = "Override for the VPC CNI addon version. When null, the version is resolved via local.eks_addon_versions in modules/app_eks/add-ons.tf (default lookup by var.cluster_version, with optional preroll override via var.eks_addons_preroll_version for preroll-eligible addons)."
  type        = string
  default     = null
}

variable "eks_addon_metrics_server_version" {
  description = "Override for the metrics-server addon version. When null, the version is resolved via local.eks_addon_versions in modules/app_eks/add-ons.tf (default lookup by var.cluster_version, with optional preroll override via var.eks_addons_preroll_version for preroll-eligible addons)."
  type        = string
  default     = null
}

variable "external_dns_image_repository" {
  type        = string
  description = "The image repository of the external-dns to deploy."
  default     = "registry.k8s.io/external-dns/external-dns"
}

variable "external_dns_image_tag" {
  type        = string
  description = "The tag of the external-dns to deploy."
  default     = null
}

variable "aws_loadbalancer_controller_image_repository" {
  type        = string
  description = "The image repository of the aws-loadbalancer-controller to deploy."
  default     = "public.ecr.aws/eks/aws-load-balancer-controller"
}

variable "aws_loadbalancer_controller_image_tag" {
  type        = string
  description = "The tag of the aws-loadbalancer-controller to deploy."
  default     = null
}

variable "cluster_autoscaler_image_repository" {
  type        = string
  description = "The image repository of the cluster-autoscaler to deploy."
  default     = "registry.k8s.io/autoscaling/cluster-autoscaler"
}

variable "cluster_autoscaler_image_tag" {
  type        = string
  description = "The tag of the cluster-autoscaler to deploy."
  default     = null
}

variable "preserve_aws_auth_configmap" {
  description = "v17 -> v20 in-place upgrade transition flag. When true, the kube-system/aws-auth ConfigMap that the v17 community eks module managed is adopted into wandb-side state via a moved block (rather than destroyed by the v20 apply). Pair with authentication_mode = \"API_AND_CONFIG_MAP\" so both auth tables coexist during the cutover. Set back to the default (false) once access entries are confirmed working; that next apply will cleanly destroy the now-redundant ConfigMap. Fresh v20 installs should leave this at false."
  type        = bool
  default     = false
}

variable "terraform_owns_cluster_creator_entry" {
  description = <<-EOT
    Whether terraform (via the community EKS module) should own the
    `aws_eks_access_entry` resource that grants
    `AmazonEKSClusterAdminPolicy` to the IAM principal that applied
    terraform (the "cluster creator"). In both paths the cluster
    creator ends up with admin permissions on the cluster — the
    variable only controls who manages the entry, not whether the
    permissions exist.

    Required — no default. Set explicitly per scenario:

    - `false` — for v17 -> v20 in-place upgrades. AWS auto-migrates
      the legacy `aws-iam-authenticator` cluster-creator binding into
      a real access entry as part of the `CONFIG_MAP` ->
      `API_AND_CONFIG_MAP` transition; that entry is AWS-owned, not
      terraform-state-owned. If the community EKS module ALSO tries
      to create one (i.e. this variable is `true`), the apply 409s
      with `ResourceInUseException`.
    - `true` — for fresh v20 installs. AWS does not auto-create a
      cluster-creator access entry for clusters created at
      `API_AND_CONFIG_MAP` without a `CONFIG_MAP`-only predecessor.
      Setting this `true` makes the community EKS module create the
      entry as a terraform-managed resource, which is necessary to
      bootstrap the in-apply kubernetes/helm providers' admin access.

    Forwarded 1:1 to the community module's
    `enable_cluster_creator_admin_permissions` input.
    See docs/upgrade-eks-20.md for the full rationale.
  EOT
  type        = bool
}

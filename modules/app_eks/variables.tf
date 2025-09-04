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

variable "lb_security_group_inbound_id" {
  type = string
}

variable "map_accounts" {
  description = "Additional AWS account numbers to add to the aws-auth configmap. See examples/basic/variables.tf for example format."
  type        = list(string)
  default     = []
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
  description = "The version of the EFS CSI driver to install. Check the docs for more information about the compatibility https://docs.aws.amazon.com/eks/latest/userguide/vpc-add-on-update.html."
  type        = string
}

variable "eks_addon_ebs_csi_driver_version" {
  description = "The version of the EBS CSI driver to install. Check the docs for more information about the compatibility https://docs.aws.amazon.com/eks/latest/userguide/vpc-add-on-update.html."
  type        = string
}

variable "eks_addon_coredns_version" {
  description = "The version of the CoreDNS addon to install. Check the docs for more information about the compatibility https://docs.aws.amazon.com/eks/latest/userguide/vpc-add-on-update.html."
  type        = string
}

variable "eks_addon_kube_proxy_version" {
  description = "The version of the kube-proxy addon to install. Check the docs for more information about the compatibility https://docs.aws.amazon.com/eks/latest/userguide/vpc-add-on-update.html."
  type        = string
}

variable "eks_addon_vpc_cni_version" {
  description = "The version of the VPC CNI addon to install. Check the docs for more information about the compatibility https://docs.aws.amazon.com/eks/latest/userguide/vpc-add-on-update.html."
  type        = string
}

variable "eks_addon_metrics_server_version" {
  description = "The version of the metrics-server addon to install. Check compatibility with `aws eks describe-addon-versions --region $REGION --kubernetes-version $EKS_CLUSTER_VERSION`"
  type        = string
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

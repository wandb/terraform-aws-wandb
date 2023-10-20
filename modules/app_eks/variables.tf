variable "bucket_arn" {
  type     = string
  nullable = false
}

variable "bucket_kms_key_arn" {
  description = "The Amazon Resource Name of the KMS key with which S3 storage bucket objects will be encrypted."
  type        = string
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
  type        = list(string)
  default     = ["m4.large"]
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

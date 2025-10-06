variable "namespace" {
  type        = string
  description = "The namespace for the bufstream resources"
}

variable "cluster_name" {
  type        = string
  description = "The EKS cluster name for tagging"
}

variable "node_role_name" {
  type        = string
  description = "The name of the EKS node IAM role to attach the bufstream policy to"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}

variable "deletion_protection" {
  type        = bool
  description = "Whether to enable deletion protection on the bucket"
  default     = true
}

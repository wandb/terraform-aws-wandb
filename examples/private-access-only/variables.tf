variable "namespace" {
  type        = string
  description = "Name prefix used for resources"
}

variable "allowed_inbound_cidr" {
  default  = ["0.0.0.0/0"]
  nullable = false
  type     = list(string)
}


variable "allowed_inbound_ipv6_cidr" {
  default  = ["::/0"]
  nullable = false
  type     = list(string)
}

variable "eks_cluster_version" {
  description = "EKS cluster kubernetes version"
  default     = "1.26"
  nullable    = false
  type        = string
}

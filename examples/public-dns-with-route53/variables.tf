# =============================================================================
# Required Variables
# =============================================================================

variable "namespace" {
  type        = string
  description = "Name prefix used for all AWS resources (e.g., 'wandb-prod', 'wandb-staging')"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.namespace))
    error_message = "Namespace must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "domain" {
  type        = string
  description = "Domain name for the W&B deployment (e.g., 'wandb.example.com'). A new Route53 hosted zone will be created for this domain."

  validation {
    condition     = can(regex("^[a-z0-9.-]+$", var.domain))
    error_message = "Domain must be a valid domain name."
  }
}

variable "subdomain" {
  type        = string
  description = "Subdomain for accessing the W&B UI (e.g., 'app'). Final URL will be subdomain.domain or just domain if null."
  default     = null
}

variable "license" {
  type        = string
  description = "W&B license key for the deployment. Obtain from https://deploy.wandb.ai"
  sensitive   = true

  validation {
    condition     = length(var.license) > 0
    error_message = "License key is required. Obtain one from https://deploy.wandb.ai"
  }
}

variable "aws_region" {
  type        = string
  description = "AWS region for the W&B deployment (e.g., 'us-west-2', 'us-east-1')"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.aws_region))
    error_message = "AWS region must be a valid region identifier."
  }
}

# =============================================================================
# EKS Configuration Variables
# =============================================================================

variable "eks_cluster_version" {
  type        = string
  description = "EKS cluster Kubernetes version (e.g., '1.30', '1.31')"
  default     = "1.30"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+$", var.eks_cluster_version))
    error_message = "EKS cluster version must be in format 'X.Y' (e.g., '1.30')."
  }
}

variable "eks_addon_kube_proxy_version" {
  type        = string
  description = "Version of the kube-proxy EKS addon. Must be compatible with eks_cluster_version."
  default     = null
}

# =============================================================================
# Network Access Control Variables
# =============================================================================

variable "allowed_inbound_cidr" {
  type        = list(string)
  description = "List of allowed IPv4 CIDR blocks for inbound traffic to W&B. Use ['0.0.0.0/0'] for public access or specific CIDRs for restricted access."
  default     = ["0.0.0.0/0"]

  validation {
    condition     = length(var.allowed_inbound_cidr) > 0
    error_message = "At least one IPv4 CIDR block must be specified."
  }
}

variable "allowed_inbound_ipv6_cidr" {
  type        = list(string)
  description = "List of allowed IPv6 CIDR blocks for inbound traffic. Use ['::/0'] for public IPv6 access."
  default     = ["::/0"]

  validation {
    condition     = length(var.allowed_inbound_ipv6_cidr) > 0
    error_message = "At least one IPv6 CIDR block must be specified."
  }
}
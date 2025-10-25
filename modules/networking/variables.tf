variable "create_vpc" {
  description = "Controls if VPC should be created (it affects almost all resources)"
  type        = bool
  default     = true
}

variable "namespace" {
  type        = string
  description = "(Required) The name prefix for all resources created."
}

variable "cidr" {
  type        = string
  description = "(Required) CIDR block for VPC."
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "(Required) List of private subnet CIDR ranges to create in VPC."
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "(Required) List of public subnet CIDR ranges to create in VPC."
}

variable "database_subnet_cidrs" {
  type        = list(string)
  description = "(Required) List of database subnet CIDR ranges to create in VPC."
}

variable "elasticache_subnet_cidrs" {
  type        = list(string)
  description = "(Optional) List of redis subnet CIDR ranges to create in VPC."
  default     = []
}

variable "pod_subnet_cidrs" {
  type        = list(string)
  description = "(Required) List of pod subnet CIDR ranges to create in VPC."
}

variable "create_elasticache_subnet" {
  type        = bool
  description = "Boolean indicating whether to provision a subnet for elasticache."
  default     = false
}

variable "enable_vpn_gateway" {
  type        = bool
  description = "(Optional) Should be true if you want to create a new VPN Gateway resource and attach it to the VPC."
  default     = false
}

variable "customer_gateways" {
  description = "(Optional) Maps of Customer Gateway's attributes (BGP ASN and Gateway's Internet-routable external IP address)"
  type        = map(map(any))
  default     = {}
}

variable "amazon_side_asn" {
  description = "The Autonomous System Number (ASN) for the Amazon side of the gateway. By default the virtual private gateway is created with the current default Amazon ASN."
  type        = string
  default     = "64512"
}

variable "clickhouse_endpoint_service_id" {
  description = "The ID of the Clickhouse service endpoint"
  type        = string
  default     = ""
}

variable "enable_flow_log" {
  description = "Controls whether VPC Flow Logs are enabled"
  type        = bool
  default     = false
}

variable "keep_flow_log_bucket" {
  description = "Controls whether S3 bucket storing VPC Flow Logs will be kept"
  type        = bool
  default     = true
}

variable "enable_s3_https_only" {
  description = "Controls whether HTTPS-only is enabled for s3 buckets"
  type        = bool
  default     = false
}
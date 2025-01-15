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
  description = "(Optional) CIDR block for VPC."
  default     = "10.10.0.0/16"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "(Optional) List of private subnet CIDR ranges to create in VPC."
  default     = ["10.10.0.0/24", "10.10.1.0/24"]
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "(Optional) List of public subnet CIDR ranges to create in VPC."
  default     = ["10.10.10.0/24", "10.10.11.0/24"]
}

variable "database_subnet_cidrs" {
  type        = list(string)
  description = "(Optional) List of database subnet CIDR ranges to create in VPC."
  default     = ["10.10.20.0/24", "10.10.21.0/24"]
}

variable "elasticache_subnet_cidrs" {
  type        = list(string)
  description = "(Optional) List of redis subnet CIDR ranges to create in VPC."
  default     = ["10.10.30.0/24", "10.10.31.0/24"]
}

variable "create_elasticache_subnet" {
  type        = bool
  description = "Boolean indicating whether to provision a subnet for elasticache."
  default     = false
}

variable "enable_vpc_flow_logs" {
  description = "Controls whether VPC Flow Logs are enabled"
  type        = bool
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

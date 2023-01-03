data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  create_vpc = var.create_vpc

  # VPC
  name                 = "${var.namespace}-vpc"
  enable_dns_hostnames = true
  enable_dns_support   = true

  azs                 = data.aws_availability_zones.available.names
  cidr                = var.cidr
  private_subnets     = var.private_subnet_cidrs
  public_subnets      = var.public_subnet_cidrs
  database_subnets    = var.database_subnet_cidrs
  elasticache_subnets = var.create_elasticache_subnet ? var.elasticache_subnet_cidrs : []

  enable_nat_gateway = true
  single_nat_gateway = false
  enable_vpn_gateway = var.enable_vpn_gateway
  customer_gateways  = var.customer_gateways

  create_igw = true

  manage_default_security_group  = true
  default_security_group_egress  = []
  default_security_group_ingress = []
}
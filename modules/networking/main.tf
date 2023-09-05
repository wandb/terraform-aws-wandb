data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 4.0"

  create_vpc = var.create_vpc

  amazon_side_asn   = var.amazon_side_asn
  azs               = data.aws_availability_zones.available.names
  cidr              = var.cidr
  create_igw        = true
  customer_gateways = var.customer_gateways
  database_subnets  = var.database_subnet_cidrs
  # setting these to empty shouldn't interfere
  # with SG rules attached to SGs
  default_security_group_egress  = []
  default_security_group_ingress = []
  elasticache_subnets            = var.create_elasticache_subnet ? var.elasticache_subnet_cidrs : []
  enable_dns_hostnames           = true
  enable_dns_support             = true
  enable_nat_gateway             = true
  enable_vpn_gateway             = var.enable_vpn_gateway
  manage_default_security_group  = true
  map_public_ip_on_launch        = true
  name                           = "${var.namespace}-vpc"
  private_subnets                = var.private_subnet_cidrs
  public_subnets                 = var.public_subnet_cidrs
  single_nat_gateway             = false
}

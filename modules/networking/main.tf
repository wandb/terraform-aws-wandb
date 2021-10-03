data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  # VPC
  name                 = "${var.namespace}-vpc"
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Subnet
  map_public_ip_on_launch = true

  azs             = data.aws_availability_zones.available.names
  cidr            = var.network_cidr
  private_subnets = var.network_private_subnet_cidrs
  public_subnets  = var.network_public_subnet_cidrs

  enable_nat_gateway = true
  single_nat_gateway = false

  create_igw = true

  manage_default_security_group = true
}
data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 4.0"

  create_vpc = var.create_vpc

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

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_vpc_endpoint" "clickhouse" {
  count = var.create_vpc && var.clickhouse_endpoint_service_id

  vpc_id              = module.vpc.vpc_id
  service_name        = var.clickhouse_endpoint_service_id
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  private_dns_enabled = true
}

# VPC FLow Logs
resource "aws_flow_log" "vpc_flow_logs" {
  count = var.create_vpc && var.enable_flow_log ? 1 : 0

  log_destination      = aws_s3_bucket.flow_log.arn
  log_destination_type = "s3"
  traffic_type         = "REJECT"
  vpc_id               = module.vpc.vpc_id
}

resource "aws_s3_bucket" "flow_log" {
  bucket = "vpc-logs"
}
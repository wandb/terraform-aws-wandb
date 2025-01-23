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
  count = var.create_vpc && length(var.clickhouse_endpoint_service_id) > 0 ? 1 : 0

  vpc_id              = module.vpc.vpc_id
  service_name        = var.clickhouse_endpoint_service_id
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  private_dns_enabled = true
}

# VPC FLow Logs
resource "aws_flow_log" "vpc_flow_logs" {
  count = var.create_vpc && var.enable_flow_log ? 1 : 0

  log_destination      = aws_s3_bucket.flow_log[0].arn
  log_destination_type = "s3"
  traffic_type         = "REJECT"
  vpc_id               = module.vpc.vpc_id
}

resource "aws_s3_bucket" "flow_log" {
  count         = (var.create_vpc && var.enable_flow_log) || var.keep_flow_log_bucket ? 1 : 0
  bucket        = "${var.namespace}-vpc-flow-logs"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "flow_log_https_only" {
  count  = var.enable_s3_https_only ? 1 : 0
  bucket = aws_s3_bucket.flow_log[0].bucket

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # Allow VPC flow logs to write to the S3 bucket
      {
        Sid       = "AllowVPCFlowLogsWrite",
        Effect    = "Allow",
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        },
        Action    = "s3:PutObject",
        Resource = "arn:aws:s3:::${aws_s3_bucket.flow_log[0].bucket}/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      # Deny all HTTP requests (HTTPS-only policy)
      {
        Sid       = "DenyHTTPRequests",
        Effect    = "Deny",
        Principal = "*",
        Action    = "s3:*",
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.flow_log[0].bucket}",
          "arn:aws:s3:::${aws_s3_bucket.flow_log[0].bucket}/*"
        ],
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket.flow_log]
}
provider "aws" {
  region = "us-east-2"

  default_tags {
    tags = {
      GithubRepo = "terraform-aws-wandb"
      GithubOrg  = "wandb"
      Enviroment = "Example"
      Example    = "PrivateAccessOnly"
    }
  }
}

module "networking" {
  source    = "../../modules/networking"
  namespace = var.namespace

  amazon_side_asn = 64620

  # Should be true if you want to create a new VPN Gateway resource and attach it to the VPC
  enable_vpn_gateway = true
  customer_gateways = {
    IP1 = {
      bgp_asn    = 65220
      ip_address = "172.83.124.10"
    }
  }
}

module "vpn_gateway" {
  source  = "terraform-aws-modules/vpn-gateway/aws"
  version = "~> 2.0"

  vpc_id              = module.networking.vpc_id
  vpn_gateway_id      = module.networking.vgw_id
  customer_gateway_id = module.networking.cgw_ids[0]

  # precalculated length of module variable vpc_subnet_route_table_ids
  vpc_subnet_route_table_count = 3
  vpc_subnet_route_table_ids   = module.networking.private_route_table_ids

  # tunnel inside cidr & preshared keys (optional)
  # tunnel1_inside_cidr   = var.custom_tunnel1_inside_cidr
  # tunnel2_inside_cidr   = var.custom_tunnel2_inside_cidr
  # tunnel1_preshared_key = var.custom_tunnel1_preshared_key
  # tunnel2_preshared_key = var.custom_tunnel2_preshared_key
}


resource "aws_route53_zone" "private" {
  name = "wandb.internal"

  vpc {
    vpc_id = module.networking.vpc_id
  }
}

module "standard" {
  source = "../../"

  namespace     = var.namespace
  public_access = false

  wandb_license = var.wandb_license

  domain_name = aws_route53_zone.private.name
  zone_id     = aws_route53_zone.private.zone_id

  # Creating a custom VPC so that we can initalize a route53 zone first and configure a vpn
  create_vpc              = false
  network_id              = module.networking.vpc_id
  network_private_subnets = module.networking.private_subnets
  network_public_subnets  = module.networking.public_subnets

  kubernetes_encrypt_ebs_volume  = true
}

output "url" {
  value = module.standard.url
}
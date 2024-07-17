output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "The identity of the VPC in which resources will be delpoyed."
}

output "vgw_id" {
  value       = module.vpc.vgw_id
  description = "The ID of the VPN Gateway."
}

output "cgw_ids" {
  value       = module.vpc.cgw_ids
  description = "List of IDs of Customer Gateway."
}

output "private_subnets" {
  value       = module.vpc.private_subnets
  description = "A list of the identities of the private subnetworks in which resources will be deployed."
}

output "public_subnets" {
  value       = module.vpc.public_subnets
  description = "A list of the identities of the public subnetworks in which resources will be deployed."
}

output "private_subnet_cidrs" {
  value       = module.vpc.private_subnets_cidr_blocks
  description = "A list of the CIDR blocks which comprise the private subnetworks."
}

output "database_subnets" {
  value       = module.vpc.database_subnets
  description = "A list of the CIDR blocks which comprise the database subnetworks."
}

output "database_subnet_cidrs" {
  value       = module.vpc.database_subnets_cidr_blocks
  description = "A list of the CIDR blocks which comprise the database subnetworks."
}

output "database_subnet_group" {
  value       = module.vpc.database_subnet_group
  description = "ID of database subnet group."
}

output "database_subnet_group_name" {
  value       = module.vpc.database_subnet_group_name
  description = "Name of database subnet group."
}

output "elasticache_subnet_group_name" {
  value       = module.vpc.elasticache_subnet_group_name
  description = "Name of elasticache subnet group."
}

output "elasticache_subnet_cidrs" {
  value       = module.vpc.elasticache_subnets_cidr_blocks
  description = "A list of the CIDR blocks which comprise the elasticache subnetworks."
}

output "elasticache_subnets" {
  value       = module.vpc.elasticache_subnets
  description = "A list of IDs of elasticache subnets"
}

output "private_route_table_ids" {
  value       = module.vpc.private_route_table_ids
  description = "List of IDs of private route tables"
}

output "clickhouse_private_hostname" {
  value       = aws_vpc_endpoint.clickhouse.dns_entry[0].hostname
  description = "The private DNS hostname of the Clickhouse VPC endpoint."
}

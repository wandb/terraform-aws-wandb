output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "The identity of the VPC in which resources will be delpoyed."
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
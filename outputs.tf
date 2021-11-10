# KMS
output "kms_key_arn" {
  value       = aws_kms_key.key.arn
  description = "The Amazon Resource Name of the KMS key used to encrypt data at rest."
}

output "kms_key_id" {
  value       = aws_kms_key.key.key_id
  description = "The identity of the KMS key used to encrypt data at rest."
}

# Network
output "network_id" {
  value       = local.network_id
  description = "The identity of the VPC in which resources are deployed."
}

output "network_private_subnets" {
  value       = local.network_private_subnets
  description = "The identities of the private subnetworks deployed within the VPC."

}

output "network_public_subnets" {
  value       = local.network_public_subnets
  description = "The identities of the public subnetworks deployed within the VPC."
}

output "database_port" {
  value = module.database.port
}
output "url" {
  value       = local.url
  description = "The URL to the W&B application"
}

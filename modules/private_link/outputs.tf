output "service_name" {
  description = "The service name of the VPC Endpoint Service"
  value       = aws_vpc_endpoint_service.private_link.service_name
}

output "service_id" {
  description = "The ID of the VPC Endpoint Service"
  value       = aws_vpc_endpoint_service.private_link.id
}

output "availability_zones" {
  description = "The Availability Zones where the NLB endpoints are available"
  value       = aws_vpc_endpoint_service.private_link.availability_zones
}

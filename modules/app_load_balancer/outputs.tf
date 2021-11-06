output "dns_name" {
  value = aws_lb.alb.dns_name
}

output "security_group_inbound_id" {
  value = aws_security_group.inbound.id
}
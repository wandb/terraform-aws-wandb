output "security_group_inbound_id" {
  value = aws_security_group.inbound.id
}
output "nlb_security_group" {
  value = var.enable_private_only_traffic ? aws_security_group.inbound_private[0].id : null
}

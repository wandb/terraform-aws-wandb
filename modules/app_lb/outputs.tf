output "dns_name" {
  value = aws_lb.alb.dns_name
}

output "security_group_inbound_id" {
  value = aws_security_group.inbound.id
}

output "lb_arn" {
  value = aws_lb.alb.arn
}

output "tg_app_arn" {
  value = aws_lb_target_group.app.arn
}

output "alb_name" {
value =  aws_lb.alb.arn
}

output "nlb_security_group" {
  value = var.enable_private_only_traffic? aws_security_group.inbound-private[0].id : null
}
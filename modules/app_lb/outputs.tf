output "dns_name" {
  value = aws_lb.alb.dns_name
}

output "security_group_inbound_ids" {
  value = concat([for sg in aws_security_group.inbound : sg.id])
}

output "lb_arn" {
  value = aws_lb.alb.arn
}

output "tg_app_arn" {
  value = aws_lb_target_group.app.arn
}
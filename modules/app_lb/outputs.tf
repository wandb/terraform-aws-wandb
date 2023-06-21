output "dns_name" {
  value = aws_lb.alb.dns_name
}


output "inbound_security_group_ids" {
  value = tolist([aws_security_group.inbound-http.id, aws_security_group.inbound-https.id])
}


output "lb_arn" {
  value = aws_lb.alb.arn
}


output "security_group_inbound_http_id" {
  value = aws_security_group.inbound-http.id
}


output "security_group_inbound_https_id" {
  value = aws_security_group.inbound-https.id
}


output "tg_app_arn" {
  value = aws_lb_target_group.app.arn
}


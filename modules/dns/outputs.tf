output "zone_id" {
  value = data.aws_route53_zone.zone.zone_id
}

output "acm_certificate_arn" {
  value = var.acm_certificate_arn == null ? aws_acm_certificate.certificate[0].arn : var.acm_certificate_arn
}
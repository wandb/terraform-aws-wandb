data "aws_route53_zone" "zone" {
  name         = var.external_dns ? "${var.subdomain}.${var.domain_name}" : var.domain_name
  private_zone = var.private_zone
}

resource "aws_acm_certificate" "certificate" {
  count = var.acm_certificate_arn == null ? 1 : 0

  domain_name = data.aws_route53_zone.zone.name
  subject_alternative_names = [
    "*.${data.aws_route53_zone.zone.name}",
    "${var.subdomain}.${data.aws_route53_zone.zone.name}",
  ]
  validation_method = "DNS"

  # Recommended by Terraform to make live-swaps smooth
  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "curaihealth-certificate"
  }
}

resource "aws_route53_record" "certificate_records" {
  for_each = var.acm_certificate_arn == null ? {
    for dvo in aws_acm_certificate.certificate[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.zone.zone_id
}

resource "aws_acm_certificate_validation" "validation" {
  count = var.acm_certificate_arn == null ? 1 : 0

  certificate_arn         = aws_acm_certificate.certificate[0].arn
  validation_record_fqdns = [for record in aws_route53_record.certificate_records : record.fqdn]
}
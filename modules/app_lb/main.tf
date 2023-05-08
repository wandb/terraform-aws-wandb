locals {
  http_port  = 80
  https_port = 443
}

locals {
  allowed_inbound_cidr_chunks = chunklist(var.allowed_inbound_cidr, 29)
  allowed_inbound_ipv6_cidr_chunks = chunklist(var.allowed_inbound_ipv6_cidr, 29)
}

resource "aws_security_group" "inbound" {
  for_each = { for index, chunk in local.allowed_inbound_cidr_chunks : index => chunk }
  name        = "${var.namespace}-alb-inbound-${each.key}"
  description = "Allow http(s) traffic to wandb"
  vpc_id      = var.network_id
}

resource "aws_security_group_rule" "https_ingress" {
  for_each = { for index, chunk in local.allowed_inbound_cidr_chunks : index => chunk }
  security_group_id = aws_security_group.inbound[each.key].id

  type             = "ingress"
  from_port        = local.https_port
  to_port          = local.https_port
  protocol         = "tcp"
  description      = "Allow HTTPS (port ${local.https_port}) traffic inbound to W&B LB"
  cidr_blocks      = try(each.value,[])
  # ipv6_cidr_blocks = local.allowed_inbound_ipv6_cidr_chunks[each.key]
  ipv6_cidr_blocks = try(local.allowed_inbound_ipv6_cidr_chunks[each.key], [])
}


resource "aws_security_group_rule" "http_ingress" {
  for_each = { for index, chunk in local.allowed_inbound_cidr_chunks : index => chunk }
  security_group_id = aws_security_group.inbound[each.key].id

  type             = "ingress"
  from_port        = local.http_port
  to_port          = local.http_port
  protocol         = "tcp"
  description      = "Allow HTTP (port ${local.http_port}) traffic inbound to W&B LB"
  cidr_blocks      = try(each.value,[])
  # ipv6_cidr_blocks = local.allowed_inbound_ipv6_cidr_chunks[each.key]
  ipv6_cidr_blocks = try(local.allowed_inbound_ipv6_cidr_chunks[each.key], [])
}

resource "aws_security_group" "outbound" {
  name        = "${var.namespace}-alb-outbound"
  vpc_id      = var.network_id
  description = "Allow all traffic outbound from W&B"

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_lb" "alb" {
  # Force replacement of ALB if the number of SG's changes. 
  # this allows SG's to be deleted if rules get removed.
  name               = "${var.namespace}-alb-${length(local.allowed_inbound_cidr_chunks)}"
  internal           = (var.load_balancing_scheme == "PRIVATE")
  load_balancer_type = "application"
  security_groups    = concat([for sg in aws_security_group.inbound : sg.id], [aws_security_group.outbound.id])
  subnets            = var.load_balancing_scheme == "PRIVATE" ? var.network_private_subnets : var.network_public_subnets
}

locals {
  https_enabled = var.acm_certificate_arn != null
}

# The acm_certificate_arn is conditionally created depending on other resources.
# Terraform needs to know how many resources to create at apply time. Therefore,
# we must always create a http and https listener.

# Create http target group if http is not enabled
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = local.http_port
  protocol          = "HTTP"

  # HTTPS Enabled
  dynamic "default_action" {
    for_each = local.https_enabled ? [1] : []
    content {
      type = "redirect"

      redirect {
        port        = local.https_port
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  # HTTPS Disabled
  dynamic "default_action" {
    for_each = local.https_enabled ? [] : [1]
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.app.arn
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = local.https_port

  protocol        = local.https_enabled ? "HTTPS" : "HTTP"
  ssl_policy      = local.https_enabled ? var.ssl_policy : null
  certificate_arn = local.https_enabled ? var.acm_certificate_arn : null

  # HTTPS Enabled
  dynamic "default_action" {
    for_each = local.https_enabled ? [1] : []
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.app.arn
    }
  }

  # HTTPS Disabled
  dynamic "default_action" {
    for_each = local.https_enabled ? [] : [1]
    content {
      type = "redirect"

      redirect {
        port        = local.http_port
        protocol    = "HTTP"
        status_code = "HTTP_301"
      }
    }
  }
}

resource "aws_lb_target_group" "app" {
  name     = "${var.namespace}-tg-app"
  port     = var.target_port
  vpc_id   = var.network_id
  protocol = "HTTP"

  health_check {
    path                = "/healthz"
    protocol            = "HTTP"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

# Create record for route53 zone.
resource "aws_route53_record" "alb" {
  zone_id = var.zone_id
  name    = var.fqdn
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "extra" {
  for_each = toset(var.extra_fqdn)
  zone_id = var.zone_id
  name    = each.value
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}
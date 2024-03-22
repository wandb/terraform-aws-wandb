locals {
  http_port  = 80
  https_port = 443
}

resource "aws_security_group" "inbound-private" {
  count       = var.enable_private_only_traffic ? 1 : 0
  name        = "${var.namespace}-nlb-inbound-private-endpoint"
  description = "Allow http(s) traffic to wandb"
  vpc_id      = var.network_id

  dynamic "ingress" {
    for_each = var.private_endpoint_cidr
    content {
      from_port   = local.https_port
      to_port     = local.https_port
      protocol    = "tcp"
      description = "Allow HTTPS (port ${local.https_port}) traffic inbound to W&B LB"
      cidr_blocks = [ingress.value]
    }
  }

  dynamic "ingress" {
    for_each = var.private_endpoint_cidr
    content {
      from_port   = local.http_port
      to_port     = local.http_port
      protocol    = "tcp"
      description = "Allow HTTP (port ${local.http_port}) traffic inbound to W&B LB"
      cidr_blocks = [ingress.value]
    }
  }
}


resource "aws_security_group" "inbound" {
  name        = "${var.namespace}-alb-inbound"
  description = "Allow http(s) traffic to wandb"
  vpc_id      = var.network_id

  ingress {
    from_port        = local.https_port
    to_port          = local.https_port
    protocol         = "tcp"
    description      = "Allow HTTPS (port ${local.https_port}) traffic inbound to W&B LB"
    cidr_blocks      = var.allowed_inbound_cidr
    ipv6_cidr_blocks = var.allowed_inbound_ipv6_cidr
  }

  ingress {
    from_port        = local.http_port
    to_port          = local.http_port
    protocol         = "tcp"
    description      = "Allow HTTP (port ${local.http_port}) traffic inbound to W&B LB"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group_rule" "alb_http_traffic" {
  count                    = var.enable_private_only_traffic ? 1 : 0
  type                     = "ingress"
  from_port                = local.http_port
  to_port                  = local.http_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.inbound.id
  source_security_group_id = aws_security_group.inbound-private[0].id
}

resource "aws_security_group_rule" "alb_https_traffic" {
  count                    = var.enable_private_only_traffic ? 1 : 0
  type                     = "ingress"
  from_port                = local.https_port
  to_port                  = local.https_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.inbound.id
  source_security_group_id = aws_security_group.inbound-private[0].id
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
  name               = "${var.namespace}-alb"
  internal           = (var.load_balancing_scheme == "PRIVATE")
  load_balancer_type = "application"
  security_groups    = [aws_security_group.inbound.id, aws_security_group.outbound.id]
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
  zone_id  = var.zone_id
  name     = each.value
  type     = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}

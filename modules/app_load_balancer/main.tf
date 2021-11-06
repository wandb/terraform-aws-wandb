resource "aws_security_group" "inbound" {
  name        = "${var.namespace}-alb-inbound"
  description = "Allow http(s) traffic to wandb"
  vpc_id      = var.network_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    description = "Allow HTTPS (port 443) traffic inbound to W&B LB"
    cidr_blocks = var.allowed_inbound_cidr
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    description = "Allow HTTP (port 80) traffic inbound to W&B LB"
    cidr_blocks = var.allowed_inbound_cidr
  }
}

resource "aws_security_group" "outbound" {
  name        = "${var.namespace}-alb-outbound"
  vpc_id      = var.network_id
  description = "Allow all traffic outbound from W&B"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "alb" {
  name               = "${var.namespace}-alb"
  internal           = (var.load_balancing_scheme == "PRIVATE")
  load_balancer_type = "application"
  security_groups    = [aws_security_group.inbound.id, aws_security_group.outbound.id]
  subnets            = var.load_balancing_scheme == "PRIVATE" ? var.network_private_subnets : var.network_public_subnets
}

# Redirect HTTP to HTTPS
resource "aws_lb_listener" "listener_80" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS listener
resource "aws_lb_listener" "listener_443" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_443.arn
  }
}

resource "aws_lb_target_group" "tg_443" {
  name     = "${var.namespace}-alb-tg-443"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = var.network_id

  health_check {
    path     = "/healthz"
    protocol = "HTTPS"
    matcher  = "200-399"
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

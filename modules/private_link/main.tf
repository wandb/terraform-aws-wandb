locals {
  max_lb_name_length = 32 - length("-nlb")
  lb_name_truncated  = "${substr(var.namespace, 0, local.max_lb_name_length)}-nlb"
}

resource "aws_lb" "nlb" {
  name                       = local.lb_name_truncated
  internal                   = true
  load_balancer_type         = "network"
  subnets                    = var.network_private_subnets
  enable_deletion_protection = var.deletion_protection
}

resource "aws_lb_target_group" "nlb" {
  name        = "${var.namespace}-nlb-tg"
  protocol    = "TCP"
  target_type = "alb"
  port        = 443
  vpc_id      = var.vpc_id

  health_check {
    protocol            = "HTTPS"
    path                = "/healthz"
    matcher             = "200-399"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 10
    port                = "traffic-port"
  }
}

data "aws_lb" "alb" {
  name = var.alb_name
}

resource "aws_lb_target_group_attachment" "nlb_to_alb" {
  target_group_arn = aws_lb_target_group.nlb_tg.arn
  target_id        = data.aws_lb.alb.arn
}

resource "aws_vpc_endpoint_service" "private_link" {
  acceptance_required        = false
  network_load_balancer_arns = [aws_lb.nlb.arn]
  allowed_principals         = [for id in var.allowed_account_ids : "arn:aws:iam::${id}:root"]
}

resource "aws_lb_listener" "nlb" {
  load_balancer_arn = aws_lb.nlb.arn
  protocol          = "TCP"
  port              = 443

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_tg.arn
  }
}

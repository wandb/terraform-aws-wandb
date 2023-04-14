
resource "aws_vpc_endpoint_service" "default" {
  acceptance_required        = false
  network_load_balancer_arns = [aws_lb.default.arn]
  private_dns_name           = var.fqdn
}

resource "aws_lb" "default" {
  name               = "${var.namespace}-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.network_private_subnets

  enable_deletion_protection = var.deletion_protection

  tags = {
    Environment = "production"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.default
  port              = "443"
  protocol          = "HTTP"
  type              = "forward"
  target_group_arn  = aws_lb_target_group.app.arn
}

resource "aws_lb_target_group" "app" {
  name     = "${var.namespace}-tg-nlb"
  port     = "443"
  vpc_id   = var.network_id
  protocol = "HTTP"

  health_check {
    path                = "/healthz"
    protocol            = "HTTPS"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200"
  }
}
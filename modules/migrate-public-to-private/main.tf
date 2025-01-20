# get alb arn from the output of data
data "aws_lb" "alb" {
  name = "${var.namespace}-alb-k8s"
}

# Private Network Load Balancer
resource "aws_lb" "private_nlb" {
  name                             = "${var.namespace}-private-nlb"
  internal                         = true
  load_balancer_type               = "network"
  security_groups                  = [aws_security_group.nlb_sg.id]
  subnets                          = var.subnet_ids
  enable_cross_zone_load_balancing = true
}

# Security Group for NLB
resource "aws_security_group" "nlb_sg" {
  name   = "${var.namespace}-nlb-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Target Group for NLB
resource "aws_lb_target_group" "nlb_target_group" {
  name        = "${var.namespace}-private-nlb"
  target_type = "alb"
  port        = 443
  protocol    = "TCP"
  vpc_id      = var.vpc_id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health"
    protocol            = "HTTPS"
    port                = "443"
  }
}

resource "aws_lb_listener" "wandb_listener" {
  load_balancer_arn = aws_lb.private_nlb.arn
  port              = "443"
  protocol          = "TCP"
  depends_on        = [aws_lb_target_group.nlb_target_group]

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_target_group.arn
  }
}

resource "aws_lb_target_group_attachment" "wandb_tg_attachment" {
  target_group_arn = aws_lb_target_group.nlb_target_group.arn
  target_id        = data.aws_lb.alb.arn
  port             = 443
  depends_on       = [aws_lb_target_group.nlb_target_group]
}

resource "aws_route53_record" "cname_record" {
  zone_id = var.private_hosted_zone_id
  name    = var.subdomain
  type    = "CNAME"
  ttl     = 300
  records = [aws_lb.private_nlb.dns_name]

  depends_on = [aws_lb.private_nlb]
}

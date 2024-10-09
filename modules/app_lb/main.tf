locals {
  http_port  = 80
  https_port = 443
}

resource "aws_security_group" "inbound_private" {
  count       = var.enable_private_only_traffic ? 1 : 0
  name        = "${var.namespace}-nlb-inbound"
  description = "Allow http(s) inbound traffic from private endpoint to wandb"
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
  source_security_group_id = aws_security_group.inbound_private[0].id
}

resource "aws_security_group_rule" "alb_https_traffic" {
  count                    = var.enable_private_only_traffic ? 1 : 0
  type                     = "ingress"
  from_port                = local.https_port
  to_port                  = local.https_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.inbound.id
  source_security_group_id = aws_security_group.inbound_private[0].id
}

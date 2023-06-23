resource "aws_security_group_rule" "http" {
  cidr_blocks       = var.allowed_inbound_cidr
  from_port         = local.http_port
  ipv6_cidr_blocks  = var.allowed_inbound_ipv6_cidr
  protocol          = "tcp"
  security_group_id = aws_security_group.inbound.id
  to_port           = local.http_port
  type              = "ingress"
}


resource "aws_security_group_rule" "https" {
  cidr_blocks       = var.allowed_inbound_cidr
  from_port         = local.https_port
  ipv6_cidr_blocks  = var.allowed_inbound_ipv6_cidr
  protocol          = "tcp"
  security_group_id = aws_security_group.inbound.id
  to_port           = local.https_port
  type              = "ingress"
}


resource "aws_security_group_rule" "outbound_all" {
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  ipv6_cidr_blocks  = ["::/0"]
  protocol          = -1
  to_port           = 0
  type              = "egress"
  security_group_id = aws_security_group.outbound.id
}
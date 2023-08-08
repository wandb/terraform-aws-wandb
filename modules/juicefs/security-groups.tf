resource "aws_security_group" "juicefs" {
  name        = "${var.namespace}-juicefs"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "redis" {
  description              = "${var.namespace}-juicefs"
  protocol                 = "tcp"
  security_group_id        = aws_security_group.juicefsd
  source_security_group_id = var.source_security_group_id
  from_port                = 6379
  to_port                  = 6379
  type                     = "ingress"
}
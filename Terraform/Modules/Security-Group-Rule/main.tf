resource "aws_security_group_rule" "role" {
  type            = var.type
  from_port       = var.from_port
  to_port         = var.to_port
  protocol        = var.protocol
  cidr_blocks     = var.cidr

  security_group_id = var.security_group
}

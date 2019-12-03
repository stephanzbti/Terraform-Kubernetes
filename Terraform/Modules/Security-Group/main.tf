resource "aws_security_group" "security_group" {
  name        = "Terraform - SecurityGroup"
  description = "Terraform - SecurityGroup"
  vpc_id      = var.vpc

  ingress {
    from_port   = var.ingress_from_port
    to_port     = var.ingress_to_port
    protocol    = var.ingress_protocol
    cidr_blocks = var.ingress_cidr
  }

  egress {
    from_port       = var.egress_from_port
    to_port         = var.egress_to_port
    protocol        = var.egress_protocol
    cidr_blocks     = var.egress_cidr
  }
}

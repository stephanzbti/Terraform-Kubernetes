/*
    Resources
*/

resource "aws_lb_target_group" "alb_targe_group" {
  name     = var.name
  port     = var.port
  protocol = var.protocol
  vpc_id   = var.vpc

  tags     = var.tag
}
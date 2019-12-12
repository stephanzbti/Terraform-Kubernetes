resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = var.alb
  port              = var.port
  protocol          = var.protocol

  default_action {
    type             = "forward"
    target_group_arn = var.target_group
  }
}
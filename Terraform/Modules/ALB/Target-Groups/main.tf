/*
    Resources
*/

resource "aws_lb_target_group" "alb_target" {
  count           = length(var.target)

  name            = "${var.target[count.index][0]}-${count.index}"
  port            = var.target[count.index][1]
  protocol        = var.target[count.index][2]
  vpc_id          = var.target[count.index][3].id

  tags            = var.tags
}
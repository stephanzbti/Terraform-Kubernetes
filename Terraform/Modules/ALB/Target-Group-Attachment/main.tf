/*
    Resources
*/

resource "aws_lb_target_group_attachment" "target_group_attachment" {
  count                 = length(var.target_group[1])

  target_group_arn      = var.target_group[0]
  target_id             = var.target_group[1].ids[count.index]
  port                  = var.target_group[2]
}

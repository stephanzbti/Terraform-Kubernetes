/*
    Resources
*/

resource "aws_lb" "alb" {
  count                      = length(var.alb)

  name                       = var.alb[count.index][0]
  internal                   = var.alb[count.index][1]
  load_balancer_type         = var.alb[count.index][2]
  security_groups            = var.alb[count.index][3].*.id
  subnets                    = var.alb[count.index][4].*.id

  enable_deletion_protection = var.alb[count.index][5]

  tags                       = var.tags
}
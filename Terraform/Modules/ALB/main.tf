/*
    Resources
*/

resource "aws_lb" "alb_kubernetes" {
  name               = "ALB-Kubernetes"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.security_group
  subnets            = var.subnets

  enable_deletion_protection = true

  tags = var.tag
}
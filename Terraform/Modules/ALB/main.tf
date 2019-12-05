/*
    Resources
*/

resource "aws_s3_bucket" "alb_s3_bucket_log" {
  bucket = "${var.project_name}-${var.environment}-alb-log"
  acl    = "private"
  force_destroy = true
}

resource "aws_lb" "alb_kubernetes" {
  name               = "ALB-Kubernetes"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.security_group
  subnets            = var.subnets

  enable_deletion_protection = true

  access_logs {
    bucket  = "${var.project_name}-${var.environment}-alb-log"
    prefix  = "ALB-Log"
    enabled = true
  }

  tags = var.tag
}
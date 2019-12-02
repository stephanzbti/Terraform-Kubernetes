/*
    Resource
*/

resource "aws_acm_certificate" "certificate" {
  domain_name       = var.dns
  validation_method = "DNS"

  tags = var.tag

  lifecycle {
    create_before_destroy = true
  }
}

/*
    Resources
*/

resource "aws_route53_zone" "route53" {
  name = var.dns

  tags = var.tags
}
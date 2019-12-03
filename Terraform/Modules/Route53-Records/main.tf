/*
    Resource
*/

resource "aws_route53_record" "www" {
  zone_id = var.route53
  name    = var.resource_record_name
  type    = var.type
  ttl     = var.ttl

  records = [var.resource_record_value]
}
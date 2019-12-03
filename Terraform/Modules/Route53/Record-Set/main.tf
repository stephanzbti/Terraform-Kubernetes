resource "aws_route53_record" "www" {
  zone_id = var.zone_id
  name    = var.resource_record_name
  type    = "CNAME"
  ttl     = "300"

  records = [var.resource_record_value]
}
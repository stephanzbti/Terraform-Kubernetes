/*
    Resource
*/

resource "aws_route53_record" "record" {
  count   = length(var.route53)

  zone_id = var.route53[count.index][0]
  name    = var.route53[count.index][1]
  type    = var.route53[count.index][2]
  ttl     = var.route53[count.index][3]

  records = var.route53[count.index][4]
}
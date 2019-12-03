/*
    Data
*/

data "aws_caller_identity" "user_identity" {}
data "aws_region" "user_identity_region" {}

/*
  Modules
*/

module "acm" {
  source = "../ACM"
  
  dns = "${var.environment}.${data.aws_caller_identity.user_identity.account_id}.${data.aws_region.user_identity_region.name}.${var.project_name}.com"
  tag = var.tag
}

/*
    Resources
*/

resource "aws_route53_zone" "route53" {
  name = "${var.environment}.${data.aws_caller_identity.user_identity.account_id}.${data.aws_region.user_identity_region.name}.${var.project_name}.com"

  tags = var.tag
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.route53.zone_id
  name    = module.acm.resource_record_name
  type    = "CNAME"
  ttl     = "300"

  records = [module.acm.resource_record_value]

  depends_on = [
    aws_route53_zone.route53
  ]
}


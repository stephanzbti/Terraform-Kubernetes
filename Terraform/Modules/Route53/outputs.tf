/*
    Outputs
*/

output "route53" {
  value = aws_route53_zone.route53.zone_id
}
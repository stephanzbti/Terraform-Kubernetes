/*
  Output Values
*/

output "zone_id" {
  value       = aws_route53_zone.route53.zone_id
  description = "Route 53 - Zone ID"
}
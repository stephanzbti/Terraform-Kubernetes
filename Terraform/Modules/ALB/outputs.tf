/*
  Output Values
*/

output "alb" {
  value       = aws_lb.alb_kubernetes.arn
  description = "ALB - Arn"
}

output "dns_name" {
  value       = aws_lb.alb_kubernetes.dns_name
  description = "ALB - Dns Name"
}
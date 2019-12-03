/*
  Output Values
*/

output "lb_listener" {
  value       = aws_lb_listener.lb_listener.arn
  description = "ALB Listener - ARN"
}
/*
  Output Values
*/

output "target_group" {
  value       = aws_lb_target_group.alb_targe_group.arn
  description = "Target Group - ARN"
}
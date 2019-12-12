/*
  Output Values
*/

output "target_group" {
  value       = aws_lb_target_group.alb_target
  description = "Target Group"
}
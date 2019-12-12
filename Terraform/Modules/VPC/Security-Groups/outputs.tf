/*
    Outputs
*/

output "security_group" {
  value       = aws_security_group.security
  description = "Security Group"
}
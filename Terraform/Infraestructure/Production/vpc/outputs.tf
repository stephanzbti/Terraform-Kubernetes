/*
  Output Values
*/

output "subnet1" {
  value       = aws_subnet.first_zone.id
  description = "EKS - Subnet1"
}

output "subnet2" {
  value       = aws_subnet.second_zone.id
  description = "EKS - Subnet2"
}

output "vpc" {
  value       = aws_vpc.kubernetes_vpc.id
  description = "EKS - VPC ID"
}
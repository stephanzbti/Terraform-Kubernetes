/*
  Output Values
*/

output "subnet" {
  value       = [ aws_subnet.first_zone.id, aws_subnet.second_zone.id ]
  description = "EKS - Subnet1"
}

output "subnet_nodegroup" {
  value       = [ aws_subnet.nodegroup_subnet1.id, aws_subnet.nodegroup_subnet2.id ]
  description = "EKS - Node Group Subnet"
}

output "vpc" {
  value       = aws_vpc.kubernetes_vpc.id
  description = "EKS - VPC ID"
}
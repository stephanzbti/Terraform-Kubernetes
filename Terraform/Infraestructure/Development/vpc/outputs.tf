/*
  Output Values
*/

output "vpc" {
  value       = module.vpc.vpc
  description = "VPC"
}

output "subnet_public" {
  value       = module.subnets.subnet_public
  description = "Subnet Public"
}

output "subnet_private" {
  value       = module.subnets.subnet_private
  description = "Subnet Private"
}

output "security_loadbalancer" {
  value       = module.security_loadbalanecer.security_group
  description = "Security Group Load Balancer"
}

output "security_eks_nodegroup" {
  value       = module.security_eks_nodegroup.security_group
  description = "Security Group Load Balancer"
}
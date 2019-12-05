/*
  Output Values
*/

output "eks_node_group_autoscalling" {
  value       = aws_eks_node_group.eks_node_group.resources.autoscaling_groups
  description = "EKS NodeGroup - Auto Scalling"
}
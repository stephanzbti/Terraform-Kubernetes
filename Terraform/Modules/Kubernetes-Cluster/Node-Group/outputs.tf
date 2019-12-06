/*
  Output Values
*/

output "eks_node_group_autoscalling" {
  value       = aws_eks_node_group.eks_node_group.resources[0].autoscaling_groups
  description = "EKS NodeGroup - Auto Scalling"
}
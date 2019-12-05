/*
    Outputs
*/

output "cluster_name" {
  value = aws_eks_cluster.kubernetes_cluster.name
}
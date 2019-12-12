/*
    Outputs
*/

output "cluster_eks" {
  value = aws_eks_cluster.kubernetes_cluster
}
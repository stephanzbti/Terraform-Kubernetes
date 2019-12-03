/*
    Outputs
*/

output "cluster_name" {
  value = aws_eks_cluster.kubernetes_cluster.name
}

output "endpoint" {
  value = "${aws_eks_cluster.kubernetes_cluster.endpoint}"
}

output "kubeconfig-certificate-authority-data" {
  value = "${aws_eks_cluster.kubernetes_cluster.certificate_authority.0.data}"
}
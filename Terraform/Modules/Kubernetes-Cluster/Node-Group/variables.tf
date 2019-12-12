/*
    Variables
*/

variable "eks_cluster" {
  description = "EKS - Kubernetes Cluster"
  type        = any
}

variable "eks_node_group" {
  description = "EKS - Node Group"
  type        = list
}
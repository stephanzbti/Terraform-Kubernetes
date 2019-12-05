/*
    Variables
*/

variable "eks_name" {
  description = "EKS - Kubernetes Cluster Name"
  type        = string
}

variable "subnet_nodegroup" {
  description = "EKS - Node Group Subnet"
  type        = list
}

variable "instance_type" {
  description = "EKS - Node Group Instance Type"
  type        = list
}
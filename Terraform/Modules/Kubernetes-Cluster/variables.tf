/*
    Variables
*/

variable "cluster_name" {
  description = "EKS - Kubernetes Cluster Name"
  type        = string
}

variable "subnet" {
  description = "EKS - Kubernetes Cluster Subnet"
  type        = list
}

variable "tags" {
  description = "EKS - Kubernetes Cluster Tags"
  type        = map
}
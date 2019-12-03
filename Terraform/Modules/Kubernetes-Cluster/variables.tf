/*
    Variables
*/

variable "cluster_name" {
  description = "EKS - Kubernetes Cluster Name"
  type        = string
}

variable "instance_type" {
  description = "EKS - Kubernetes Cluster Instance Type"
  type        = list
}

variable "environments" {
  description = "EKS - Kubernetes Cluster Environment"
  type        = string
}

variable "subnet" {
  description = "EKS - Kubernetes Cluster Subnet"
  type        = list
}

variable "subnet_nodegroup" {
  description = "EKS - Kubernetes Cluster Subnet Node Group"
  type        = list
}

variable "vpc" {
  description = "EKS - Kubernetes Cluster VPC"
  type        = string
}

variable "tag" {
  description = "EKS - Kubernetes Cluster Tags"
  type        = any
}
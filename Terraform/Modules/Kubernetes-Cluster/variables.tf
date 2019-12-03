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

variable "subnet1" {
  description = "EKS - Kubernetes Cluster Subnet1"
  type        = string
}

variable "subnet2" {
  description = "EKS - Kubernetes Cluster Subnet2"
  type        = string
}

variable "vpc" {
  description = "EKS - Kubernetes Cluster VPC"
  type        = string
}

variable "tag" {
  description = "EKS - Kubernetes Cluster Tags"
  type        = any
}
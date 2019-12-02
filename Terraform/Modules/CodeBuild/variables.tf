/*
    Variables
*/

variable "project_name" {
  description = "CodeBuild - Project Name"
  type        = string
}

variable "cluster_name" {
  description = "CodeBuild - EKS Cluster Name"
  type        = string
}

variable "environment" {
  description = "CodeBuild - Environment"
  type        = string
}


variable "kms_id" {
  description = "CodeBuild - S3 KMS Key ID"
  type        = string
}

variable "compute_type" {
  description = "CodeBuild - Computer Type"
  type        = string
}

variable "tag" {
  description = "CodeBuild - Tag"
  type        = any
}

variable "ecr_frontend" {
  description = "CodeBuild - ECR FrontEnd"
  type        = any
}

variable "ecr_backend" {
  description = "CodeBuild - ECR BackEnd"
  type        = any
}

variable "ecr_terraform" {
  description = "CodeBuild - ECR TerraForm"
  type        = any
}
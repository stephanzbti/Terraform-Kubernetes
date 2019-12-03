/*
    Variables
*/

variable "project_name" {
  description = "ALB - Project Name"
  type        = string
}

variable "environment" {
  description = "ALB - Environment"
  type        = string
}

variable "tag" {
  description = "ALB - Tag"
  type        = any
}

variable "security_group" {
  description = "ALB - Security Group"
  type        = list
}

variable "subnets" {
  description = "ALB - Subnets"
  type        = list
}
/*
    Variables
*/

variable "tags" {
  description = "ALB - Tag"
  type        = map
}

variable "name" {
  description = "ALB - Name"
  type        = string
}

variable "port" {
  description = "ALB - Port"
  type        = number
}

variable "protocol" {
  description = "ALB - Protocol"
  type        = string
}

variable "vpc" {
  description = "ALB - VPC"
  type        = string
}
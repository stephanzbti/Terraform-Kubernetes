/*
    Variables
*/

variable "project_name" {
  description = "Route 53 - Route 53 Project Name"
  type        = string
}

variable "environment" {
  description = "Route 53 - Route 53 Environment"
  type        = string
}

variable "tag" {
  description = "Route 53 - Tag"
  type        = any
}
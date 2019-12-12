/*
    Variables
*/

variable "vpc" {
  description   = "Internet Gateway - VPC"
  type          = any
}

variable "tags" {
  description = "Internet Gateway - Tags"
  type        = map
}
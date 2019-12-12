/*
    Variables
*/

variable "tags" {
  description = "VPC - Tags"
  type        = map
}

variable "cidr_block" {
  description = "VPC - CIDR Blocks"
  type        = string
}
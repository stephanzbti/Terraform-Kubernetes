/*
    Variables
*/

variable "max_subnet_count" {
  description   = "Subnet - Max Subnet"
  type          = number
  default       = 0
}

variable "vpc" {
  description   = "Subnet - VPC"
  type          = any
}

variable "cidr_block" {
  description   = "Subnet - Max Subnet"
  type          = string
  default       = ""
}

variable "igw" {
  description   = "Subnet - Internet Gateway"
  type          = any
}

variable "ngw" {
  description   = "Subnet - Nat Gateway"
  type          = any
}

variable "tags" {
  description   = "Subnet - VPC"
  type          = map
}
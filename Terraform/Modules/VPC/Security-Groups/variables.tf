/*
    Variables
*/

variable "vpc" {
    description   = "Security Group - VPC"
    type          = any
}

variable "ingress" {
    description   = "Security Group - Ingress"
    type          = list
}

variable "egress" {
    description   = "Security Group - Egress"
    type          = list
}

variable "tags" {
    description   = "Internet Gateway - Tags"
    type          = map
}
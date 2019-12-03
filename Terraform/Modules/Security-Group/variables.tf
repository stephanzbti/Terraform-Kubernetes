/*
    Variables
*/

variable "vpc" {
  description = "Security Group - ingress VPC"
  type        = string
}

variable "ingress_from_port" {
  description = "Security Group - ingress from Port"
  type        = number
}

variable "ingress_to_port" {
  description = "Security Group - ingress to Port"
  type        = number
}

variable "ingress_protocol" {
  description = "Security Group - ingress Protocol"
  type        = string
}

variable "ingress_cidr" {
  description = "Security Group - Ingress CIDR"
  type        = list
}

variable "egress_from_port" {
  description = "Security Group - egress from Port"
  type        = number
}

variable "egress_to_port" {
  description = "Security Group - egress to Port"
  type        = number
}

variable "egress_protocol" {
  description = "Security Group - egress Protocol"
  type        = string
}

variable "egress_cidr" {
  description = "Security Group - egress CIDR"
  type        = list
}
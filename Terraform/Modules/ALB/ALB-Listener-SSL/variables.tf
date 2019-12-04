/*
    Variables
*/

variable "alb" {
  description = "Listener - ALB"
  type        = string
}

variable "port" {
  description = "Listener - Port"
  type        = string
}

variable "protocol" {
  description = "Listener - Protocol"
  type        = string
}

variable "certificate" {
  description = "Listener - Certificate"
  type        = string
}

variable "target_group" {
  description = "Listener - Target Group"
  type        = string
}
/*
    Variables
*/

variable "dns" {
  description = "Route 53 - DNS"
  type        = string
}

variable "tag" {
  description = "Route 53 - Tag"
  type        = any
}
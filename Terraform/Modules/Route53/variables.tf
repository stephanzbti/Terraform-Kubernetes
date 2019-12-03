/*
    Variables
*/

variable "dns" {
  description = "Route 53 - Zone Name"
  type        = string
}

variable "tag" {
  description = "Route 53 - Tag"
  type        = any
}
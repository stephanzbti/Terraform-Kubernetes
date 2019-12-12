/*
    Variables
*/

variable "dns" {
  description = "ACM - DNS Name"
  type        = string
}

variable "tags" {
  description = "ACM - Tag"
  type        = any
}
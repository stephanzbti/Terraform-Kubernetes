/*
    Variables
*/

variable "dns" {
  description = "Route 53 - Zone Name"
  type        = string
}

variable "tags" {
  description = "Route 53 - Tag"
  type        = map
}
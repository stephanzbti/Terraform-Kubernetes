/*
    Variables
*/

variable "tags" {
  description = "ALB - Tag"
  type        = map
}

variable "target" {
  description = "ALB - Target Group"
  type        = list
}
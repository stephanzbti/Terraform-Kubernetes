/*
    Variables
*/

variable "route53" {
  description = "Route 53 - Zone Name"
  type        = string
}

variable "resource_record_name" {
  description = "Route 53 - Record Name"
  type        = string
}

variable "type" {
  description = "Route 53 - Type"
  type        = string
}

variable "ttl" {
  description = "Route 53 - TTL"
  type        = string
}

variable "resource_record_value" {
  description = "Route 53 - Record Value"
  type        = string
}
/*
    Variables
*/

variable "resource_record_name" {
  description = "Route 53 - Resource Record Name"
  type        = string
}

variable "resource_record_value" {
  description = "Route 53 - REsource Record Value"
  type        = string
}

variable "zone_id" {
  description = "Route 53 - Zone ID"
  type        = string
}
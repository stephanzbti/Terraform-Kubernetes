/*
    Variables
*/

variable "tags" {
    description = "Nat Gateways - Tags"
    type        = map
}

variable "gateways" {
    description = "Nat Gateways - Gateway"
    type        = any
}
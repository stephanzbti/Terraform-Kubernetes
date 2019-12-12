/*
    Variables
*/

variable "from_port" {
    description   = "Security Group Rule - From Port"
    type          = number
}

variable "to_port" {
    description   = "Security Group Rule - To Port"
    type          = number
}

variable "protocol" {
    description   = "Security Group Rule - Protocol"
    type          = string
}

variable "cidr_block" {
    description   = "Security Group Rule - CIDR Block"
    type          = list
}

variable "security_group" {
    description   = "Security Group Rule - Security Group"
    type          = any
}

/*
    Resources
*/

resource "aws_nat_gateway" "gw" {
    count           = length(var.gateways)

    allocation_id   = var.gateways[count.index][0]
    subnet_id       = var.gateways[count.index][1]

    tags            = var.tags
}
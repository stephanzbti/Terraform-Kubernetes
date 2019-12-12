/*
    Resources
*/

resource "aws_security_group" "security" {
    count               = length(var.ingress)

    vpc_id              = var.vpc.id

    ingress {
        from_port       = var.ingress[count.index][0]
        to_port         = var.ingress[count.index][1]
        protocol        = var.ingress[count.index][2]
        cidr_blocks     = var.ingress[count.index][3]
    }

    egress {
        from_port       = var.egress[count.index][0]
        to_port         = var.egress[count.index][1]
        protocol        = var.egress[count.index][2]
        cidr_blocks     = var.egress[count.index][3]
    }

    tags = var.tags
}
/*
  Data
*/

data "aws_availability_zones" "available" {
    state = "available"
}

/*
    Variables
*/

locals {
    private_subnet_count = var.max_subnet_count == 0 ? length(data.aws_availability_zones.available.names) : var.max_subnet_count
}

/*
    Resources
*/

/*
    Private
*/

resource "aws_subnet" "private" {
    count               = length(data.aws_availability_zones.available.names)/2
    vpc_id              = var.vpc.id
    availability_zone   = element(data.aws_availability_zones.available.names, count.index)

    cidr_block = cidrsubnet(
        signum(length(var.cidr_block)) == 1 ? var.cidr_block : var.vpc.cidr_block,
        ceil(log(local.private_subnet_count * 2, 2)),
        count.index
    )

    tags = var.tags
}

resource "aws_route_table" "private" {
    vpc_id      = var.vpc.id

    tags        = var.tags
}

resource "aws_route_table_association" "private" {
    count             = length(data.aws_availability_zones.available.names)/2
    subnet_id         = element(aws_subnet.private.*.id, count.index)
    route_table_id    = element(aws_route_table.private.*.id, count.index)
}

resource "aws_route" "private" {
    route_table_id         = join("", aws_route_table.private.*.id)
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id         = var.ngw.id
}

resource "aws_network_acl" "private" {
    vpc_id     = var.vpc.id
    subnet_ids = aws_subnet.private.*.id

    egress {
      rule_no    = 100
      action     = "allow"
      cidr_block = "0.0.0.0/0"
      from_port  = 0
      to_port    = 0
      protocol   = "-1"
    }

    ingress {
      rule_no    = 100
      action     = "allow"
      cidr_block = "0.0.0.0/0"
      from_port  = 0
      to_port    = 0
      protocol   = "-1"
    }

    tags = var.tags
}

/*
    Public
*/

resource "aws_subnet" "public" {
    count                   = length(data.aws_availability_zones.available.names)/2
    vpc_id                  = var.vpc.id
    availability_zone       = element(data.aws_availability_zones.available.names, count.index+length(data.aws_availability_zones.available.names)/2)
    map_public_ip_on_launch = true


    cidr_block = cidrsubnet(
        signum(length(var.cidr_block)) == 1 ? var.cidr_block : var.vpc.cidr_block,
        ceil(log(local.private_subnet_count * 2, 2)),
        count.index+length(data.aws_availability_zones.available.names)/2
    )

    tags = var.tags
}

resource "aws_route_table" "public" {
    vpc_id = var.vpc.id

    tags = var.tags
}

resource "aws_route" "public" {
    route_table_id         = join("", aws_route_table.public.*.id)
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = var.igw.id
}

resource "aws_route_table_association" "public" {
    count          = length(data.aws_availability_zones.available.names)/2
    
    subnet_id      = element(aws_subnet.public.*.id, count.index)
    route_table_id = aws_route_table.public.id
}


resource "aws_network_acl" "public" {
    vpc_id     = var.vpc.id
    subnet_ids = aws_subnet.public.*.id

    egress {
      rule_no    = 100
      action     = "allow"
      cidr_block = "0.0.0.0/0"
      from_port  = 0
      to_port    = 0
      protocol   = "-1"
    }

    ingress {
      rule_no    = 100
      action     = "allow"
      cidr_block = "0.0.0.0/0"
      from_port  = 0
      to_port    = 0
      protocol   = "-1"
    }

    tags = var.tags
}
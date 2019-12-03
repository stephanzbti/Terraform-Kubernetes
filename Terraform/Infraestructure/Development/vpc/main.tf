/*
  Data
*/

data "aws_availability_zones" "available" {
  state = "available"
}

/*
    VPC
*/

resource "aws_vpc" "kubernetes_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames  = true

  tags  = var.tag
}

/*
  Subnet - EKS Cluster
*/

resource "aws_subnet" "first_zone" {
  vpc_id              = aws_vpc.kubernetes_vpc.id
  cidr_block          = "10.0.1.0/24"
  availability_zone   = "us-east-1a"

  depends_on = [
      aws_vpc.kubernetes_vpc
  ]
}

resource "aws_subnet" "second_zone" {
  vpc_id              = aws_vpc.kubernetes_vpc.id
  cidr_block          = "10.0.2.0/24"
  availability_zone   = "us-east-1b"

  depends_on = [
      aws_vpc.kubernetes_vpc
  ]
}


/*
  Subnet NodeGroup
*/

resource "aws_subnet" "nodegroup_subnet1" {
  availability_zone = data.aws_availability_zones.available.names[3]
  cidr_block        = cidrsubnet(aws_vpc.kubernetes_vpc.cidr_block, 8, 3)
  vpc_id            = aws_vpc.kubernetes_vpc.id

  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

resource "aws_subnet" "nodegroup_subnet2" {
  availability_zone = data.aws_availability_zones.available.names[4]
  cidr_block        = cidrsubnet(aws_vpc.kubernetes_vpc.cidr_block, 8, 4)
  vpc_id            = aws_vpc.kubernetes_vpc.id

  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

/*
  Internet Gateway
*/

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.kubernetes_vpc.id

  tags  = var.tag

  depends_on                = [
    aws_vpc.kubernetes_vpc
  ]
}

resource "aws_route" "route" {
  route_table_id            = aws_vpc.kubernetes_vpc.default_route_table_id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.internet_gateway.id
  depends_on                = [
    aws_vpc.kubernetes_vpc
  ]
}
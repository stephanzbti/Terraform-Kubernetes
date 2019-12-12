/*
    Networks
*/

module "vpc" {
    source          = "../../../Modules/VPC/"

    cidr_block      = var.cidr_block
    tags            = var.tags
}

/*
    Gateways
*/

module "igw" {
    source          = "../../../Modules/VPC/Internet-Gateway"

    vpc             = module.vpc.vpc  
    tags            = var.tags
}

module "ngw" {
    source          = "../../../Modules/VPC/Nat-Gateway"

    gateways        = [[module.eip.eip.id, module.subnets.subnet_public[0].id]] 
    tags            = var.tags
}

module "eip" {
    source          = "../../../Modules/VPC/Elastic-IP"

    tags            = var.tags
}

/*
  Subnets
*/

module subnets {
    source          = "../../../Modules/VPC/Subnets"

    vpc             = module.vpc.vpc
    igw             = module.igw.igw
    ngw             = module.ngw.gateways[0]
    tags            = var.tags
}

/*
  Security Groups
*/

module "security_loadbalanecer" {
    source          = "../../../Modules/VPC/Security-Groups"

    vpc             = module.vpc.vpc
    ingress         = [[ 80, 80, "tcp", ["0.0.0.0/0"]], [ 443, 443, "tcp", ["0.0.0.0/0"]]]
    egress          = [[ 0, 0, "-1", ["0.0.0.0/0"]], [ 0, 0, "-1", ["0.0.0.0/0"]]]

    tags            = var.tags
}

module "security_eks_nodegroup" {
    source          = "../../../Modules/VPC/Security-Groups"

    vpc             = module.vpc.vpc
    ingress         = [[ 80, 80, "tcp", [module.vpc.vpc.cidr_block]], [ 443, 443, "tcp", [module.vpc.vpc.cidr_block]], [ 1025, 65535, "tcp", [module.vpc.vpc.cidr_block]]]
    egress          = [[ 0, 0, "-1", [module.vpc.vpc.cidr_block]], [ 0, 0, "-1", [module.vpc.vpc.cidr_block]], [ 0, 0, "-1", [module.vpc.vpc.cidr_block]]]

    tags            = var.tags
}
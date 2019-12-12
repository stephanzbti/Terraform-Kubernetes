/*
    Terraform Backend
*/

terraform {
  backend "s3" {
    bucket         = "terraform-state-files-teste"
    key            = "Infraestructure/Development/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-development-locks"
    encrypt        = false
  }
}

/*
    Providers
*/

provider "aws" { }

/*
  Data
*/

data "aws_caller_identity" "user_identity" {}
data "aws_region" "user_identity_region" {}

locals {
  tags = {
    Developer                                      = "Stephan Zandona Bartkowiak"
    Date                                           = "12/12/2019"
    Project                                        = "DevOps - Terraform EKS Complete"
    Environment                                    = "Development"
    "kubernetes.io/cluster/${local.cluster_name}"  = "shared"
  }
  cluster_name    = "k8s-development"
  dns             = "${local.cluster_name}.${data.aws_caller_identity.user_identity.account_id}.${data.aws_region.user_identity_region.name}.com"
  cname           = "application"
  cidr_block      = "10.0.0.0/16"
}

/*
    Internal Module
*/

module "vpc" {
  source = "./vpc/"

  tags          = local.tags
  cidr_block    = local.cidr_block
}

/*
    Kubernetes
*/

module "kubernetes" {
  source = "../../Modules/Kubernetes-Cluster"
  
  cluster_name  = local.cluster_name
  subnet        = [
    module.vpc.subnet_public[0], 
    module.vpc.subnet_private[0]
  ]
  tags          = local.tags
}

module "kubernetes_node_group" {
  source = "../../Modules/Kubernetes-Cluster/Node-Group"

  eks_cluster       = module.kubernetes.cluster_eks
  eks_node_group    = [
    [
      module.vpc.subnet_private, 
      ["t2.medium"], 
      1, 
      1, 
      1
    ]
  ]
}

/*
  Route 53
*/

module "route53" {
  source = "../../Modules/Route53"
  
  dns            = local.dns
  tags           = local.tags  
}

module "acm" {
  source = "../../Modules/ACM"
  
  dns           = local.dns
  tags          = local.tags
}

module "route53-records" {
  source                  = "../../Modules/Route53/Route53-Records"

  route53                 = [
    [
      module.route53.route53.zone_id,
      module.acm.acm.domain_validation_options.0.resource_record_name, 
      "CNAME", 
      "300", 
      [module.acm.acm.domain_validation_options.0.resource_record_value]
    ]
  ]
}

module "route53-records-acm" {
  source                  = "../../Modules/Route53/Route53-Records"

  route53                 = [
    [
      module.route53.route53.zone_id,
      "${local.cname}.${local.dns}", 
      "CNAME", 
      "300", 
      [module.alb.alb[0].dns_name]
    ]
  ]
}

/*
  ALB
*/

module "alb" {
  source                  = "../../Modules/ALB"
  
  alb                     = [
    [
      "alb-${local.cluster_name}",
      false,
      "application",
      module.vpc.security_loadbalancer,
      concat(module.vpc.subnet_public, module.vpc.subnet_private),
      false
    ]
  ]
  tags                    = local.tags
}

module "alb_target" {
  source                = "../../Modules/ALB/Target-Groups"
  
  target                = [
    [
      local.cluster_name,
      31987,
      "HTTP",
      module.vpc.vpc
    ],
    [
      local.cluster_name,
      32078,
      "HTTP",
      module.vpc.vpc
    ]
  ]

  tags                    = local.tags
}

# module "alb_listener" {
#   source = "../../Modules/ALB/ALB-Listener"
  
#   alb             = module.alb.alb
#   port            = "80"
#   protocol        = "HTTP"
#   target_group    = module.alb_targe_group_1.target_group
# }
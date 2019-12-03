/*
    Terraform Backend
*/

terraform {
  backend "s3" {
    bucket         = "terraform-state-files-hotmart"
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

/* Variables 
    tags: Reponsible to tag all resourcers from this TF.
*/

locals {
    tags = {
        Developer   = "Stephan Zandona Bartkowiak"
        Date        = "28/11/2019"
        Project     = "Hotmart Teste DevOps 2019"
        Environment = "Development"
    }
    environment     = "development"
    cluster_name    = "k8s-hotmart"
    instance_type   = [ "t3.medium" ]
    dns             = "${local.environment}.${local.cluster_name}.${data.aws_caller_identity.user_identity.account_id}.${data.aws_region.user_identity_region.name}.com"
}

data "aws_caller_identity" "user_identity" {}
data "aws_region" "user_identity_region" {}

/*
    Internal Module
*/

module "vpc" {
  source = "./vpc/"

  tag          = local.tags
}


/*
    Kubernetes
*/

module "kubernetes" {
  source = "../../Modules/Kubernetes-Cluster"
  
  cluster_name  = local.cluster_name
  subnet1       = module.vpc.subnet1
  subnet2       = module.vpc.subnet2
  vpc           = module.vpc.vpc
  tag           = local.tags
  environments  = local.environment
  instance_type = local.instance_type
}

/*
  Route 53
*/

module "route53" {
  source = "../../Modules/Route53"

  tag           = local.tags  
  dns           = local.dns
}

module "acm" {
  source = "../../Modules/ACM"
  
  dns = "*.${local.dns}"
  tag = local.tags
}

module "route53_record_set" {
  source = "../../Modules/Route53/Record-Set"
  
  resource_record_value  = module.acm.resource_record_value
  resource_record_name   = module.acm.resource_record_name
  zone_id                = module.route53.zone_id 
}
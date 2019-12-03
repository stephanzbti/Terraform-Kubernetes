/*
    Terraform Backend
*/

terraform {
  backend "s3" {
    bucket         = "terraform-state-files-hotmart"
    key            = "Infraestructure/Production/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
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
        Environment = "Production"
    }
    environment     = "Production"
    cluster_name    = "Kubernetes-Hotmart"
    instance_type   = [ "c5.large" ]
}

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
  
  project_name  = local.cluster_name
  environment   = local.environment
  tag           = local.tags  
}
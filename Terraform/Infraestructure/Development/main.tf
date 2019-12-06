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

/*
  Data
*/

data "aws_caller_identity" "user_identity" {}
data "aws_region" "user_identity_region" {}

data "aws_instances" "aws_eks_node_group_machine" {
  instance_tags = {
    "kubernetes.io/cluster/${kubernetes.cluster_name}" = "owned"
  }

  instance_state_names = ["running", "stopped"]
}

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
  cname           = "application"
}

/*
    Internal Module
*/

module "vpc" {
  source = "./vpc/"

  tag          = local.tags
  cluster_name = module.kubernetes.cluster_name
}

/*
    Kubernetes
*/

module "kubernetes" {
  source = "../../Modules/Kubernetes-Cluster"
  
  cluster_name  = local.cluster_name
  subnet        = module.vpc.subnet
  vpc           = module.vpc.vpc
  tag           = local.tags
  environments  = local.environment
}

module "kubernetes_node_group" {
  source = "../../Modules/Kubernetes-Cluster/Node-Group"

  eks_name          = module.kubernetes.cluster_name
  subnet_nodegroup  = module.vpc.subnet_nodegroup
  instance_type     = local.instance_type
}

/*
  Route 53
*/

module "route53" {
  source = "../../Modules/Route53"
  
  dns           = local.dns
  tag           = local.tags  
}

module "acm" {
  source = "../../Modules/ACM"
  
  dns = local.dns
  tag = local.tags
}

module "route53-records" {
  source = "../../Modules/Route53/Route53-Records"

  route53                 = module.route53.route53
  resource_record_name    = module.acm.resource_record_name
  type                    = "CNAME"
  ttl                     = "300"
  resource_record_value   = module.acm.resource_record_value
}


/*
  ALB
*/

module "security_group" {
  source = "../../Modules/Security-Group"
  
  vpc                 = module.vpc.vpc
  ingress_from_port   = 80
  ingress_to_port     = 80
  ingress_protocol    = "tcp"
  ingress_cidr        = ["0.0.0.0/0"]
  egress_from_port    = 0
  egress_to_port      = 0
  egress_protocol     = "-1"
  egress_cidr         = ["0.0.0.0/0"]
}

module "security_group_rule" {
  source = "../../Modules/Security-Group/Security-Group-Rule"
  
  security_group  = module.security_group.security_group
  type            = "ingress"
  from_port       = 443
  to_port         = 443
  protocol        = "tcp"
  cidr            = ["0.0.0.0/0"]
}

module "alb" {
  source = "../../Modules/ALB"
  
  project_name  = local.cluster_name
  environment   = local.environment
  tag           = local.tags  
  security_group  = [ module.security_group.security_group ]
  subnets         = module.vpc.subnet_nodegroup
}

module "route53-records-alb" {
  source = "../../Modules/Route53/Route53-Records"

  route53                 = module.route53.route53
  resource_record_name    = "${local.cname}.${local.dns}"
  type                    = "CNAME"
  ttl                     = "300"
  resource_record_value   = module.alb.dns_name
}


module "alb_targe_group_1" {
  source = "../../Modules/ALB/ALB-Target-Groups"
  
  tag           = local.tags 
  name          = "Terraform-Target-Group-1"
  port          = 31987
  protocol      = "HTTP"
  vpc           = module.vpc.vpc
}

module "alb_targe_group_2" {
  source = "../../Modules/ALB/ALB-Target-Groups"
  
  tag           = local.tags 
  name          = "Terraform-Target-Group-2"
  port          = 32078
  protocol      = "HTTP"
  vpc           = module.vpc.vpc
}

module "alb_listener" {
  source = "../../Modules/ALB/ALB-Listener"
  
  alb             = module.alb.alb
  port            = "80"
  protocol        = "HTTP"
  target_group    = module.alb_targe_group_1.target_group
}
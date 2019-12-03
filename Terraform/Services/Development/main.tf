/*
  Backend Terraforms
*/

terraform {
  backend "s3" {
    bucket         = "terraform-state-files-hotmart"
    key            = "Services/Development/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}

/* 
    Configure Provider
*/

provider "aws" {  }


/* Variables 
    tags: Reponsible to tag all resourcers from this TF.
    s3_kms_key: Give KMS Key ID.
*/

locals {
  tags = {
      Teste       = "Stephan Zandona Bartkowiak"
      Date        = "28/11/2019"
      Project     = "Hotmart Teste DevOps 2019"
      Environment = "Development"
  }
  project_name    = "hotmart-project"
  compute_type    = "BUILD_GENERAL1_SMALL"
  environment     = "development"
  codepipeline_source = {
    Owner       = "stephanzbti"
    Repo        = "Terraform-Kubernetes"
    Branch      = "development"
    OAuthToken  = ""
  }
  cluster_name  = "K8s-Hotmart-Development"
  environment_path = "Development"
}

data "aws_kms_key" "s3_kms_key" {
  key_id = "2761e694-2379-4512-adaa-1a40d3b65c12"
}

/*
  Module
*/

module "ecr" {
  source = "../../Modules/ECR"

  project_name      =   local.project_name
  environment       =   local.environment
}

module "codebuild" {
  source = "../../Modules/CodeBuild"
  
  kms_id            =   data.aws_kms_key.s3_kms_key.key_id
  project_name      =   local.project_name
  tag               =   local.tags
  compute_type      =   local.compute_type
  ecr_frontend      =   module.ecr.ecr_frontend
  ecr_backend       =   module.ecr.ecr_backend
  ecr_terraform     =   module.ecr.ecr_terraform
  environment       =   local.environment
  cluster_name      =   local.cluster_name
  environment_path  =    local.environment_path
}

module "codepipeline" {
  source = "../../Modules/CodePipeline"
  
  kms_id            =   data.aws_kms_key.s3_kms_key.key_id
  project_name      =   local.project_name
  tag               =   local.tags
  codebuild_name    =   module.codebuild.code_build_name
  environment       =   local.environment
  codepipeline_source            =   local.codepipeline_source
}
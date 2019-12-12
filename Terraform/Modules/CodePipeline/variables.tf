/*
    Variables
*/

variable "kms_id" {
  description = "S3 - KMS Key ID"
  type        = string
}

variable "project_name" {
  description = "CodePipeline - Project Name"
  type        = string
}

variable "environment" {
  description = "CodePipeline - Project Name"
  type        = string
}

variable "tags" {
  description = "CodePipeline - Tags"
  type        = map
}

variable "codebuild_name" {
  description = "CodePipeline - CodeBuild Project Name"
  type        = string
}

variable "codepipeline_source" {
  description = "CodePipeline - Source Configuration"
  type        = any
}

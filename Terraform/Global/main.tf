/* 
    Configure Provider
*/

provider "aws" {  } # Getting from OS Environment

/*
    Resources
*/

resource "aws_kms_key" "kms_kubernetes_cloudwatch" {
  description             = "KMS Kubernetes Cloud Watch"
}

resource "aws_kms_key" "kms_codepipeline_s3_artifact" {
  description             = "KMS CodePipeline S3 Artifact"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-state-files-hotmart"

  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"  
  attribute {
    name = "LockID"
    type = "S"
  }
}
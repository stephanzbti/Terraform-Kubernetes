/*
    Resource: CodePipeline Project
*/

resource "aws_s3_bucket" "codepipeline_artifact_bucket" {
  bucket = "${var.project_name}-${var.environment}-artifact"
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = var.kms_id
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name = "${var.project_name}-${var.environment}-codepipeline-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "${var.project_name}-${var.environment}-codepipeline-policy"
  role = aws_iam_role.codepipeline_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.codepipeline_artifact_bucket.arn}",
        "${aws_s3_bucket.codepipeline_artifact_bucket.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    }
  ]
}
EOF

  depends_on = [
    aws_s3_bucket.codepipeline_artifact_bucket,
    aws_iam_role.codepipeline_role
  ]
}

resource "aws_codepipeline" "frontend-codepipeline" {
  name     = "${var.project_name}-${var.environment}-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifact_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "SCM"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = var.codepipeline_source
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = var.codebuild_name
      }
    }
  }

#   stage {
#     name = "Deploy"

#     action {
#       name            = "Deploy"
#       category        = "Deploy"
#       owner           = "AWS"
#       provider        = "CloudFormation"
#       input_artifacts = ["build_output"]
#       version         = "1"

#       configuration = {
#         ActionMode     = "REPLACE_ON_FAILURE"
#         Capabilities   = "CAPABILITY_AUTO_EXPAND,CAPABILITY_IAM"
#         OutputFileName = "CreateStackOutput.json"
#         StackName      = "MyStack"
#         TemplatePath   = "build_output::sam-templated.yaml"
#       }
#     }
#   }

  tags = var.tag

  depends_on = [
    aws_s3_bucket.codepipeline_artifact_bucket,
    aws_iam_role.codepipeline_role
  ]
}
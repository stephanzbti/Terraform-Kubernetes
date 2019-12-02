/*
  Data
*/

data "aws_caller_identity" "user_identity" {}
data "aws_region" "user_identity_region" {}

/*
  Resource
*/

resource "aws_s3_bucket" "codebuild_cache" {
  bucket = "${var.project_name}-${var.environment}-codebuild-cache"
  acl    = "private"
  force_destroy = true

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = var.kms_id
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "aws_iam_role" "codebuild_iam_role" {
  name = "${var.project_name}-${var.environment}-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codebuild_policy" {
  role = aws_iam_role.codebuild_iam_role.name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:CompleteLayerUpload",
        "ecr:GetAuthorizationToken",
        "ecr:ListImages",
        "ecr:InitiateLayerUpload",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage",
        "ecr:UploadLayerPart"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeDhcpOptions",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeVpcs"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterfacePermission"
      ],
      "Resource": [
        "*"
      ],
      "Condition": {
        "StringEquals": {
          "ec2:Subnet": [
            "*"
          ],
          "ec2:AuthorizedService": "codebuild.amazonaws.com"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}    
POLICY

  depends_on = [
    aws_iam_role.codebuild_iam_role
  ]
}

resource "aws_codebuild_project" "codebuild_project" {
  name          = "${var.project_name}-${var.environment}-codebuild"
  description   = "CodeBuild Project - ${var.project_name}-${var.environment}"
  build_timeout = "5"
  service_role  = aws_iam_role.codebuild_iam_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.codebuild_cache.bucket
  }

  environment {
    compute_type                = var.compute_type
    image                       = "aws/codebuild/standard:2.0"
    privileged_mode             = true
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.user_identity.account_id
    }

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = data.aws_region.user_identity_region.name
    }

    environment_variable {
      name  = "IMAGE_REPO_NAME_FRONTEND"
      value = var.ecr_frontend
    }

    environment_variable {
      name  = "IMAGE_REPO_NAME_BACKEND"
      value = var.ecr_backend
    }

    environment_variable {
      name  = "IMAGE_REPO_NAME_TERRAFORM"
      value = var.ecr_terraform
    }

    environment_variable {
      name  = "PROJECT_NAME"
      value = var.project_name
    }

    environment_variable {
      name  = "REACT_APP_STAGE"
      value = var.environment
    } 

    environment_variable {
      name  = "ESK_CLUSTER_NAME"
      value = var.cluster_name
    } 
  }

  logs_config {
    cloudwatch_logs {
      group_name = "log-group"
      stream_name = "log-stream"
    }

    s3_logs {
      status = "ENABLED"
      location = "${aws_s3_bucket.codebuild_cache.id}/build-log"
    }
  }

  source {
    type            = "CODEPIPELINE"
  }

  tags = var.tag

  depends_on = [
    aws_s3_bucket.codebuild_cache,
    aws_iam_role.codebuild_iam_role
  ]
}
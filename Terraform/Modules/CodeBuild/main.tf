/*
  Data
*/

data "aws_caller_identity" "user_identity" {}
data "aws_region" "user_identity_region" {}

data "aws_iam_policy" "AdminPolcy" {
  arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

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

resource "aws_iam_role_policy" "codebuild_acm_policy" {
  role = aws_iam_role.codebuild_iam_role.name

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "eks:ListNodegroups",
                "eks:UntagResource",
                "eks:ListTagsForResource",
                "eks:UpdateClusterConfig",
                "eks:CreateNodegroup",
                "eks:DeleteCluster",
                "eks:UpdateNodegroupVersion",
                "eks:DescribeNodegroup",
                "eks:ListUpdates",
                "eks:DeleteNodegroup",
                "eks:DescribeUpdate",
                "eks:TagResource",
                "eks:UpdateNodegroupConfig",
                "eks:DescribeCluster"
            ],
            "Resource": [
                "arn:aws:eks:*:*:cluster/*",
                "arn:aws:eks:*:*:nodegroup/*/*/*"
            ]
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "eks:ListClusters",
                "eks:CreateCluster"
            ],
            "Resource": "*"
        }
    ]
}
POLICY

  depends_on = [
    aws_iam_role.codebuild_iam_role
  ]
}

resource "aws_iam_role_policy" "codebuild_acm_policy" {
  role = aws_iam_role.codebuild_iam_role.name

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "route53:ListTagsForResources",
                "route53:GetHostedZone",
                "route53:ChangeResourceRecordSets",
                "route53:ChangeTagsForResource",
                "route53:DeleteHostedZone",
                "route53:UpdateHostedZoneComment",
                "route53:CreateVPCAssociationAuthorization",
                "route53:ListTagsForResource"
            ],
            "Resource": "arn:aws:route53:::hostedzone/*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "route53:CreateHostedZone",
                "route53:CreateReusableDelegationSet",
                "route53:ListHostedZones",
                "route53:ListHostedZonesByName"
            ],
            "Resource": "*"
        }
    ]
}
POLICY

  depends_on = [
    aws_iam_role.codebuild_iam_role
  ]
}

resource "aws_iam_role_policy" "codebuild_acm_policy" {
  role = aws_iam_role.codebuild_iam_role.name

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "acm:DeleteCertificate",
                "acm:DescribeCertificate",
                "acm:GetCertificate",
                "acm:RemoveTagsFromCertificate",
                "acm:UpdateCertificateOptions",
                "acm:AddTagsToCertificate",
                "acm:RenewCertificate"
            ],
            "Resource": "arn:aws:acm:*:*:certificate/*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "acm:RequestCertificate",
                "acm:ListCertificates",
                "acm:ListTagsForCertificate"
            ],
            "Resource": "*"
        }
    ]
}
POLICY

  depends_on = [
    aws_iam_role.codebuild_iam_role
  ]
}

resource "aws_iam_role_policy" "codebuild_codepipeline_policy" {
  role = aws_iam_role.codebuild_iam_role.name

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "codepipeline:PutApprovalResult",
                "codepipeline:PutActionRevision"
            ],
            "Resource": "arn:aws:codepipeline:*:*:*/*/*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "codepipeline:EnableStageTransition",
                "codepipeline:RetryStageExecution",
                "codepipeline:DisableStageTransition"
            ],
            "Resource": "arn:aws:codepipeline:*:*:*/*"
        },
        {
            "Sid": "VisualEditor2",
            "Effect": "Allow",
            "Action": [
                "codepipeline:RegisterWebhookWithThirdParty",
                "codepipeline:PollForJobs",
                "codepipeline:TagResource",
                "codepipeline:DeleteWebhook",
                "codepipeline:DeregisterWebhookWithThirdParty",
                "codepipeline:ListWebhooks",
                "codepipeline:UntagResource",
                "codepipeline:CreateCustomActionType",
                "codepipeline:ListTagsForResource",
                "codepipeline:DeleteCustomActionType",
                "codepipeline:PutWebhook",
                "codepipeline:ListActionTypes"
            ],
            "Resource": [
                "arn:aws:codepipeline:*:*:webhook:*",
                "arn:aws:codepipeline:*:*:actiontype:*/*/*/*"
            ]
        },
        {
            "Sid": "VisualEditor3",
            "Effect": "Allow",
            "Action": [
                "codepipeline:PutThirdPartyJobFailureResult",
                "codepipeline:PutThirdPartyJobSuccessResult",
                "codepipeline:PollForThirdPartyJobs",
                "codepipeline:PutJobFailureResult",
                "codepipeline:PutJobSuccessResult",
                "codepipeline:AcknowledgeJob",
                "codepipeline:AcknowledgeThirdPartyJob",
                "codepipeline:GetThirdPartyJobDetails",
                "codepipeline:GetJobDetails"
            ],
            "Resource": "*"
        }
    ]
}
POLICY

  depends_on = [
    aws_iam_role.codebuild_iam_role
  ]
}

resource "aws_iam_role_policy" "codebuild_codebuild_policy" {
  role = aws_iam_role.codebuild_iam_role.name

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "codebuild:BatchGetProjects",
                "codebuild:DeleteWebhook",
                "codebuild:ListReportsForReportGroup",
                "codebuild:InvalidateProjectCache",
                "codebuild:DescribeTestCases",
                "codebuild:BatchGetReports",
                "codebuild:StopBuild",
                "codebuild:DeleteReportGroup",
                "codebuild:UpdateWebhook",
                "codebuild:ListBuildsForProject",
                "codebuild:CreateWebhook",
                "codebuild:CreateProject",
                "codebuild:BatchGetBuilds",
                "codebuild:UpdateReportGroup",
                "codebuild:CreateReportGroup",
                "codebuild:CreateReport",
                "codebuild:UpdateReport",
                "codebuild:DeleteReport",
                "codebuild:BatchDeleteBuilds",
                "codebuild:DeleteProject",
                "codebuild:StartBuild",
                "codebuild:BatchGetReportGroups",
                "codebuild:BatchPutTestCases"
            ],
            "Resource": [
                "arn:aws:codebuild:*:*:report-group/*",
                "arn:aws:codebuild:*:*:project/*"
            ]
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "codebuild:ImportSourceCredentials",
                "codebuild:ListReports",
                "codebuild:ListBuilds",
                "codebuild:ListCuratedEnvironmentImages",
                "codebuild:DeleteOAuthToken",
                "codebuild:ListReportGroups",
                "codebuild:ListSourceCredentials",
                "codebuild:ListProjects",
                "codebuild:DeleteSourceCredentials",
                "codebuild:ListRepositories",
                "codebuild:PersistOAuthToken",
                "codebuild:ListConnectedOAuthAccounts"
            ],
            "Resource": "*"
        }
    ]
}
POLICY

  depends_on = [
    aws_iam_role.codebuild_iam_role
  ]
}


resource "aws_iam_role_policy" "codebuild_ecr_policy" {
  role = aws_iam_role.codebuild_iam_role.name

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ecr:PutImageTagMutability",
                "ecr:DescribeImageScanFindings",
                "ecr:StartImageScan",
                "ecr:GetLifecyclePolicyPreview",
                "ecr:CreateRepository",
                "ecr:PutImageScanningConfiguration",
                "ecr:ListTagsForResource",
                "ecr:ListImages",
                "ecr:DeleteLifecyclePolicy",
                "ecr:DeleteRepository",
                "ecr:UntagResource",
                "ecr:SetRepositoryPolicy",
                "ecr:BatchGetImage",
                "ecr:DescribeImages",
                "ecr:TagResource",
                "ecr:DescribeRepositories",
                "ecr:StartLifecyclePolicyPreview",
                "ecr:DeleteRepositoryPolicy",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetRepositoryPolicy",
                "ecr:GetLifecyclePolicy"
            ],
            "Resource": "arn:aws:ecr:*:*:repository/*"
        }
    ]
}
POLICY

  depends_on = [
    aws_iam_role.codebuild_iam_role
  ]
}

resource "aws_iam_role_policy" "codebuild_ec2_policy" {
  role = aws_iam_role.codebuild_iam_role.name

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ec2:AuthorizeSecurityGroupEgress",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:DeleteTags",
                "ec2:DeleteVpcPeeringConnection",
                "ec2:AcceptVpcPeeringConnection",
                "ec2:CreateTags",
                "ec2:DeleteRoute",
                "ec2:RevokeClientVpnIngress",
                "ec2:ReplaceRoute",
                "ec2:RejectVpcPeeringConnection",
                "ec2:DeleteRouteTable",
                "ec2:RevokeSecurityGroupIngress",
                "ec2:CreateRoute",
                "ec2:RevokeSecurityGroupEgress",
                "ec2:DeleteSecurityGroup",
                "ec2:DisableVpcClassicLink",
                "ec2:CreateVpcPeeringConnection",
                "ec2:EnableVpcClassicLink"
            ],
            "Resource": [
                "arn:aws:ec2:*:*:vpc-peering-connection/*",
                "arn:aws:ec2:*:*:route-table/*",
                "arn:aws:ec2:*:*:client-vpn-endpoint/*",
                "arn:aws:ec2:*:*:security-group/*",
                "arn:aws:ec2:*:*:vpc/*"
            ]
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "ec2:DeleteSubnet",
                "ec2:DescribeInstances",
                "ec2:ModifyVpcEndpointServiceConfiguration",
                "ec2:ReplaceRouteTableAssociation",
                "ec2:DeleteVpcEndpoints",
                "ec2:AttachInternetGateway",
                "ec2:DescribeByoipCidrs",
                "ec2:AssociateVpcCidrBlock",
                "ec2:AssociateRouteTable",
                "ec2:DisassociateVpcCidrBlock",
                "ec2:DescribeInternetGateways",
                "ec2:CreateInternetGateway",
                "ec2:ModifyVpcPeeringConnectionOptions",
                "ec2:DescribeNetworkInterfacePermissions",
                "ec2:DescribeNetworkAcls",
                "ec2:DescribeRouteTables",
                "ec2:RejectVpcEndpointConnections",
                "ec2:DescribeEgressOnlyInternetGateways",
                "ec2:CreateVpcEndpointConnectionNotification",
                "ec2:DescribeVpcClassicLinkDnsSupport",
                "ec2:DescribeVpcPeeringConnections",
                "ec2:ModifyNetworkInterfaceAttribute",
                "ec2:ResetNetworkInterfaceAttribute",
                "ec2:CreateRouteTable",
                "ec2:DeleteNetworkInterface",
                "ec2:DescribeVpcEndpointServiceConfigurations",
                "ec2:DetachInternetGateway",
                "ec2:DisassociateRouteTable",
                "ec2:ModifyVpcEndpointConnectionNotification",
                "ec2:DescribeVpcClassicLink",
                "ec2:CreateNetworkInterface",
                "ec2:CreateVpcEndpointServiceConfiguration",
                "ec2:DescribeVpcEndpointServicePermissions",
                "ec2:CreateDefaultVpc",
                "ec2:AssociateSubnetCidrBlock",
                "ec2:DeleteNatGateway",
                "ec2:CreateEgressOnlyInternetGateway",
                "ec2:DeleteVpc",
                "ec2:DescribeVpcEndpoints",
                "ec2:CreateSubnet",
                "ec2:DescribeSubnets",
                "ec2:DescribeVpnGateways",
                "ec2:ModifyVpcEndpoint",
                "ec2:DeprovisionByoipCidr",
                "ec2:ModifyVpcEndpointServicePermissions",
                "ec2:DescribeAddresses",
                "ec2:CreateNatGateway",
                "ec2:DescribeInstanceAttribute",
                "ec2:DescribeRegions",
                "ec2:CreateVpc",
                "ec2:DescribeDhcpOptions",
                "ec2:DescribeVpcEndpointServices",
                "ec2:DeleteVpcEndpointServiceConfigurations",
                "ec2:DescribeVpcAttribute",
                "ec2:CreateDefaultSubnet",
                "ec2:DeleteNetworkInterfacePermission",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DescribeAvailabilityZones",
                "ec2:CreateSecurityGroup",
                "ec2:DescribeNetworkInterfaceAttribute",
                "ec2:CreateNetworkAcl",
                "ec2:ModifyVpcAttribute",
                "ec2:DescribeVpcEndpointConnections",
                "ec2:DescribeInstanceStatus",
                "ec2:DeleteEgressOnlyInternetGateway",
                "ec2:DetachNetworkInterface",
                "ec2:AcceptVpcEndpointConnections",
                "ec2:DescribeTags",
                "ec2:DescribeNatGateways",
                "ec2:DisassociateSubnetCidrBlock",
                "ec2:DescribeVpcEndpointConnectionNotifications",
                "ec2:DescribeSecurityGroups",
                "ec2:DeleteVpcEndpointConnectionNotifications",
                "ec2:DescribeSecurityGroupReferences",
                "ec2:CreateVpcEndpoint",
                "ec2:DescribeVpcs",
                "ec2:DisableVpcClassicLinkDnsSupport",
                "ec2:AttachNetworkInterface",
                "ec2:EnableVpcClassicLinkDnsSupport",
                "ec2:ModifyVpcTenancy",
                "ec2:CreateNetworkAclEntry"
            ],
            "Resource": "*"
        }
    ]
}
POLICY

  depends_on = [
    aws_iam_role.codebuild_iam_role
  ]
}

resource "aws_iam_role_policy" "codebuild_cloudwatch_policy" {
  role = aws_iam_role.codebuild_iam_role.name

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "logs:ListTagsLogGroup",
                "logs:DisassociateKmsKey",
                "logs:DescribeLogGroups",
                "logs:UntagLogGroup",
                "logs:DeleteLogGroup",
                "logs:DescribeLogStreams",
                "logs:PutMetricFilter",
                "logs:CreateLogStream",
                "logs:TagLogGroup",
                "logs:DeleteRetentionPolicy",
                "logs:AssociateKmsKey",
                "logs:PutSubscriptionFilter",
                "logs:PutRetentionPolicy",
                "logs:GetLogGroupFields"
            ],
            "Resource": "arn:aws:logs:*:*:log-group:*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "logs:GetLogEvents",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:log-group:*:log-stream:*"
        },
        {
            "Sid": "VisualEditor2",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogDelivery",
                "logs:DeleteResourcePolicy",
                "logs:GetLogRecord",
                "logs:PutResourcePolicy",
                "logs:PutDestinationPolicy",
                "logs:UpdateLogDelivery",
                "logs:DeleteLogDelivery",
                "logs:DeleteDestination",
                "logs:CreateLogGroup",
                "logs:GetLogDelivery",
                "logs:PutDestination",
                "logs:ListLogDeliveries"
            ],
            "Resource": "*"
        }
    ]
}    
POLICY

  depends_on = [
    aws_iam_role.codebuild_iam_role
  ]
}

resource "aws_iam_role_policy" "codebuild_iam_policy" {
  role = aws_iam_role.codebuild_iam_role.name

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "iam:UpdateAssumeRolePolicy",
                "iam:GetPolicyVersion",
                "iam:DeleteAccessKey",
                "iam:ListRoleTags",
                "iam:DeleteGroup",
                "iam:RemoveRoleFromInstanceProfile",
                "iam:UpdateGroup",
                "iam:CreateRole",
                "iam:AttachRolePolicy",
                "iam:PutRolePolicy",
                "iam:CreateLoginProfile",
                "iam:DetachRolePolicy",
                "iam:SimulatePrincipalPolicy",
                "iam:ListAttachedRolePolicies",
                "iam:DetachGroupPolicy",
                "iam:ListRolePolicies",
                "iam:DetachUserPolicy",
                "iam:PutGroupPolicy",
                "iam:UpdateLoginProfile",
                "iam:UpdateServiceSpecificCredential",
                "iam:GetRole",
                "iam:CreateGroup",
                "iam:GetPolicy",
                "iam:UpdateUser",
                "iam:GetAccessKeyLastUsed",
                "iam:ListEntitiesForPolicy",
                "iam:DeleteUserPolicy",
                "iam:AttachUserPolicy",
                "iam:DeleteRole",
                "iam:UpdateRoleDescription",
                "iam:UpdateAccessKey",
                "iam:GetUserPolicy",
                "iam:ListGroupsForUser",
                "iam:DeleteServiceLinkedRole",
                "iam:GetGroupPolicy",
                "iam:GetRolePolicy",
                "iam:CreateInstanceProfile",
                "iam:UntagRole",
                "iam:PutRolePermissionsBoundary",
                "iam:TagRole",
                "iam:DeletePolicy",
                "iam:DeleteRolePermissionsBoundary",
                "iam:CreateUser",
                "iam:GetGroup",
                "iam:CreateAccessKey",
                "iam:ListInstanceProfilesForRole",
                "iam:AddUserToGroup",
                "iam:RemoveUserFromGroup",
                "iam:GenerateOrganizationsAccessReport",
                "iam:DeleteRolePolicy",
                "iam:ListAttachedUserPolicies",
                "iam:ListAttachedGroupPolicies",
                "iam:CreatePolicyVersion",
                "iam:DeleteLoginProfile",
                "iam:DeleteInstanceProfile",
                "iam:GetInstanceProfile",
                "iam:ListGroupPolicies",
                "iam:PutUserPermissionsBoundary",
                "iam:DeleteUser",
                "iam:DeleteUserPermissionsBoundary",
                "iam:ListUserPolicies",
                "iam:ListInstanceProfiles",
                "iam:TagUser",
                "iam:CreatePolicy",
                "iam:UntagUser",
                "iam:CreateServiceLinkedRole",
                "iam:ListPolicyVersions",
                "iam:AttachGroupPolicy",
                "iam:PutUserPolicy",
                "iam:UpdateRole",
                "iam:GetUser",
                "iam:DeleteGroupPolicy",
                "iam:DeletePolicyVersion",
                "iam:SetDefaultPolicyVersion",
                "iam:ListUserTags"
            ],
            "Resource": [
                "arn:aws:iam::*:policy/*",
                "arn:aws:iam::*:instance-profile/*",
                "arn:aws:iam::*:user/*",
                "arn:aws:iam::*:role/*",
                "arn:aws:iam::*:access-report/*",
                "arn:aws:iam::*:group/*"
            ]
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "iam:GenerateCredentialReport",
                "iam:ListPolicies",
                "iam:GetAccountPasswordPolicy",
                "iam:DeleteAccountPasswordPolicy",
                "iam:ListPoliciesGrantingServiceAccess",
                "iam:ListRoles",
                "iam:SimulateCustomPolicy",
                "iam:UpdateAccountPasswordPolicy",
                "iam:CreateAccountAlias",
                "iam:ListAccountAliases",
                "iam:ListUsers",
                "iam:ListGroups",
                "iam:DeleteAccountAlias",
                "iam:GetAccountAuthorizationDetails"
            ],
            "Resource": "*"
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
  build_timeout = "60"
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
      name  = "EKS_CLUSTER_NAME"
      value = var.cluster_name
    } 

    environment_variable {
      name  = "ENVIRONMENT"
      value = var.environment_path
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
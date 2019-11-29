/* Local Environments 
    common_tags: Reponsible to tag all resourcers from this Tf.
*/

locals {
    tags = {
        Teste       = "Stephan Zandona Bartkowiak"
        Date        = "28/11/2019"
        Project     = "Hotmart Teste DevOps 2019"
    }
}


/* 
    Configure Provider
*/

provider "aws" {  } # Getting from OS Environment

resource "aws_vpc" "Kubernetes-VPC" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = local.tags
}

resource "aws_subnet" "First-Zone" {
  vpc_id     = "${aws_vpc.Kubernetes-VPC.id}"
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = local.tags
  }
}

resource "aws_subnet" "Second-Zone" {
  vpc_id     = "${aws_vpc.Kubernetes-VPC.id}"
  cidr_block = "10.0.2.0/24"

  tags = local.tags
}

resource "aws_subnet" "Third-Zone" {
  vpc_id     = "${aws_vpc.Kubernetes-VPC.id}"
  cidr_block = "10.0.3.0/24"

  tags = {
    Name = local.tags
  }
}

resource "aws_iam_role" "Kubernetes-Hotmart-Role" {
  name               = "Kubernetes-Hotmart-Role"
  assume_role_policy = = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "SharedSecurityGroupRelatedPermissions",
                "Effect": "Allow",
                "Action": [
                    "ec2:RevokeSecurityGroupIngress",
                    "ec2:AuthorizeSecurityGroupEgress",
                    "ec2:AuthorizeSecurityGroupIngress",
                    "ec2:DescribeInstances",
                    "ec2:RevokeSecurityGroupEgress",
                    "ec2:DeleteSecurityGroup"
                ],
                "Resource": "*",
                "Condition": {
                    "ForAnyValue:StringLike": {
                        "ec2:ResourceTag/eks": "*"
                    }
                }
            },
            {
                "Sid": "EKSCreatedSecurityGroupRelatedPermissions",
                "Effect": "Allow",
                "Action": [
                    "ec2:RevokeSecurityGroupIngress",
                    "ec2:AuthorizeSecurityGroupEgress",
                    "ec2:AuthorizeSecurityGroupIngress",
                    "ec2:DescribeInstances",
                    "ec2:RevokeSecurityGroupEgress",
                    "ec2:DeleteSecurityGroup"
                ],
                "Resource": "*",
                "Condition": {
                    "ForAnyValue:StringLike": {
                        "ec2:ResourceTag/eks:nodegroup-name": "*"
                    }
                }
            },
            {
                "Sid": "LaunchTemplateRelatedPermissions",
                "Effect": "Allow",
                "Action": [
                    "ec2:DeleteLaunchTemplate",
                    "ec2:CreateLaunchTemplateVersion"
                ],
                "Resource": "*",
                "Condition": {
                    "StringLike": {
                        "ec2:ResourceTag/eks:nodegroup-name": "*"
                    }
                }
            },
            {
                "Sid": "AutoscalingRelatedPermissions",
                "Effect": "Allow",
                "Action": [
                    "autoscaling:UpdateAutoScalingGroup",
                    "autoscaling:DeleteAutoScalingGroup",
                    "autoscaling:TerminateInstanceInAutoScalingGroup",
                    "autoscaling:CompleteLifecycleAction",
                    "autoscaling:PutLifecycleHook",
                    "autoscaling:PutNotificationConfiguration"
                ],
                "Resource": "arn:aws:autoscaling:*:*:*:autoScalingGroupName/eks-*"
            },
            {
                "Sid": "AllowAutoscalingToCreateSLR",
                "Effect": "Allow",
                "Condition": {
                    "StringEquals": {
                        "iam:AWSServiceName": "autoscaling.amazonaws.com"
                    }
                },
                "Action": "iam:CreateServiceLinkedRole",
                "Resource": "*"
            },
            {
                "Sid": "AllowASGCreationByEKS",
                "Effect": "Allow",
                "Action": [
                    "autoscaling:CreateOrUpdateTags",
                    "autoscaling:CreateAutoScalingGroup"
                ],
                "Resource": "*",
                "Condition": {
                    "ForAnyValue:StringEquals": {
                        "aws:TagKeys": [
                            "eks",
                            "eks:cluster-name",
                            "eks:nodegroup-name"
                        ]
                    }
                }
            },
            {
                "Sid": "AllowPassRoleToIAM",
                "Effect": "Allow",
                "Action": "iam:PassRole",
                "Resource": "*",
                "Condition": {
                    "StringEqualsIfExists": {
                        "iam:PassedToService": "iam.amazonaws.com"
                    }
                }
            },
            {
                "Sid": "AllowPassRoleToAutoscaling",
                "Effect": "Allow",
                "Action": "iam:PassRole",
                "Resource": "*",
                "Condition": {
                    "StringEqualsIfExists": {
                        "iam:PassedToService": "autoscaling.amazonaws.com"
                    }
                }
            },
            {
                "Sid": "AllowPassRoleToEC2",
                "Effect": "Allow",
                "Action": "iam:PassRole",
                "Resource": "*",
                "Condition": {
                    "StringEqualsIfExists": {
                        "iam:PassedToService": "ec2.amazonaws.com"
                    }
                }
            },
            {
                "Sid": "PermissionsToManageResourcesForNodegroups",
                "Effect": "Allow",
                "Action": [
                    "iam:GetRole",
                    "ec2:CreateLaunchTemplate",
                    "ec2:DescribeInstances",
                    "iam:GetInstanceProfile",
                    "ec2:DescribeLaunchTemplates",
                    "autoscaling:DescribeAutoScalingGroups",
                    "ec2:CreateSecurityGroup",
                    "ec2:DescribeLaunchTemplateVersions",
                    "ec2:RunInstances",
                    "ec2:DescribeSecurityGroups",
                    "ec2:GetConsoleOutput"
                ],
                "Resource": "*"
            },
            {
                "Sid": "PermissionsToCreateAndManageInstanceProfiles",
                "Effect": "Allow",
                "Action": [
                    "iam:CreateInstanceProfile",
                    "iam:DeleteInstanceProfile",
                    "iam:RemoveRoleFromInstanceProfile",
                    "iam:AddRoleToInstanceProfile"
                ],
                "Resource": "arn:aws:iam::*:instance-profile/eks-*"
            },
            {
                "Sid": "PermissionsToManageEKSAndKubernetesTags",
                "Effect": "Allow",
                "Action": [
                    "ec2:CreateTags",
                    "ec2:DeleteTags"
                ],
                "Resource": "*",
                "Condition": {
                    "ForAnyValue:StringLike": {
                        "aws:TagKeys": [
                            "eks",
                            "eks:cluster-name",
                            "eks:nodegroup-name",
                            "kubernetes.io/cluster/*"
                        ]
                    }
                }
            }
        ]
    }
    EOF

    tags = local.tags
}

resource "aws_eks_cluster" "Kubernetes-Hotmart" {
  name                      = "example"
  role_arn                  = "${aws_iam_role.Kubernetes-Hotmart-Role.arn}"
  version                   = "1.14"
  enabled_cluster_log_types = ""

  vpc_config {
    subnet_ids = ["${aws_subnet.First-Zone.id}", "${aws_subnet.Second-Zone.id}"]
  }

   tags = local.tags
}
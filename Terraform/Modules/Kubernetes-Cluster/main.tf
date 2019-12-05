/*
    Data
*/

data "aws_iam_policy" "AmazonEKSClusterPolicy" {
  arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

data "aws_iam_policy" "AmazonEKSServicePolicy" {
  arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

/*
    Resources
*/

/*
  CloudWatch
*/
resource "aws_cloudwatch_log_group" "Kubernetes-CloudWatch" {
  name              = "/aws/eks/${var.cluster_name}-${var.environments}/cluster"
  retention_in_days = 7
}

/*
  IAM
*/

resource "aws_iam_role" "Kubernetes-Role" {
  name               = "${var.cluster_name}-${var.environments}-Role"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
        "Action": "sts:AssumeRole",
        "Principal": {
        "Service": "eks.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
    }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "Kubernetes-AmazonEKSClusterPolicy-Role-Attch" {  
  role       = aws_iam_role.Kubernetes-Role.name
  policy_arn = data.aws_iam_policy.AmazonEKSClusterPolicy.arn

  depends_on = [
      aws_iam_role.Kubernetes-Role
  ]
}

resource "aws_iam_role_policy_attachment" "Kubernetes-AmazonEKSServicePolicy-Role-Attch" {
  role       = aws_iam_role.Kubernetes-Role.name
  policy_arn = data.aws_iam_policy.AmazonEKSServicePolicy.arn

  depends_on = [
      aws_iam_role.Kubernetes-Role
  ]
}

/*
  Kubernetes
*/

resource "aws_eks_cluster" "kubernetes_cluster" {
  name                      = "${var.cluster_name}-${var.environments}"
  role_arn                  = aws_iam_role.Kubernetes-Role.arn
  version                   = "1.14"
  enabled_cluster_log_types = ["api", "audit", "scheduler", "authenticator", "controllerManager"]

  vpc_config {
    subnet_ids = var.subnet
    endpoint_private_access = true
  }

  depends_on = [
      aws_cloudwatch_log_group.Kubernetes-CloudWatch,
      aws_iam_role.Kubernetes-Role,
      aws_iam_role_policy_attachment.Kubernetes-AmazonEKSServicePolicy-Role-Attch,
      aws_iam_role_policy_attachment.Kubernetes-AmazonEKSClusterPolicy-Role-Attch
  ]

  tags = var.tag
}

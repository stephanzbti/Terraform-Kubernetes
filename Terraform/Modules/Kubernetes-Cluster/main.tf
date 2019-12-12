/*
    Data
*/

data "aws_iam_policy" "amazoneksclusterpolicy" {
  arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

data "aws_iam_policy" "amazoneksservicepolicy" {
  arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

/*
    Resources
*/

/*
  CloudWatch
*/
resource "aws_cloudwatch_log_group" "kubernetes-cloudwatch" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 7
}

/*
  IAM
*/

resource "aws_iam_role" "kubernetes-role" {
  name               = "${var.cluster_name}-Role"
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

resource "aws_iam_role_policy_attachment" "kubernetes-amazoneksclusterpolicy-role-attch" {  
  role       = aws_iam_role.kubernetes-role.name
  policy_arn = data.aws_iam_policy.amazoneksclusterpolicy.arn

  depends_on = [
      aws_iam_role.kubernetes-role
  ]
}

resource "aws_iam_role_policy_attachment" "kubernetes-amazoneksservicepolicy-role-attch" {
  role       = aws_iam_role.kubernetes-role.name
  policy_arn = data.aws_iam_policy.amazoneksservicepolicy.arn

  depends_on = [
      aws_iam_role.kubernetes-role
  ]
}

/*
  Kubernetes
*/

resource "aws_eks_cluster" "kubernetes_cluster" {
  name                      = var.cluster_name
  role_arn                  = aws_iam_role.kubernetes-role.arn
  version                   = "1.14"
  enabled_cluster_log_types = ["api", "audit", "scheduler", "authenticator", "controllerManager"]

  vpc_config {
    subnet_ids = var.subnet.*.id
    endpoint_private_access = true
  }

  depends_on = [
      aws_cloudwatch_log_group.kubernetes-cloudwatch,
      aws_iam_role.kubernetes-role,
      aws_iam_role_policy_attachment.kubernetes-amazoneksservicepolicy-role-attch,
      aws_iam_role_policy_attachment.kubernetes-amazoneksclusterpolicy-role-attch
  ]

  tags = var.tags
}

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

/*
  NodeGroup
*/

/*
  IAM
*/

resource "aws_iam_role" "eks_cluster_nodegroup" {
  name = "eks-node-group-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_nodegroup_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_cluster_nodegroup.name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_nodegroup_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_cluster_nodegroup.name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_nodegroup_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_cluster_nodegroup.name
}

resource "aws_eks_node_group" "esk_node_group" {
  cluster_name    = aws_eks_cluster.kubernetes_cluster.name
  node_group_name = "EKS-Node-Group"
  node_role_arn   = aws_iam_role.eks_cluster_nodegroup.arn
  subnet_ids      = var.subnet_nodegroup
  instance_types  = var.instance_type

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_nodegroup_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_cluster_nodegroup_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks_cluster_nodegroup_AmazonEC2ContainerRegistryReadOnly,
    aws_eks_cluster.kubernetes_cluster
  ]
}

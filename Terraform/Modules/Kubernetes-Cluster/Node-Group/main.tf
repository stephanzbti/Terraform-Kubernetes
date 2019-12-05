/*
  NodeGroup
*/

resource "aws_iam_role" "eks_cluster_nodegroup_role" {
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
  role       = aws_iam_role.eks_cluster_nodegroup_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_nodegroup_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_cluster_nodegroup_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_nodegroup_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_cluster_nodegroup_role.name
}

resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = var.eks_name
  node_group_name = "EKS-Node-Group-${}"
  node_role_arn   = aws_iam_role.eks_cluster_nodegroup_role.arn
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
    aws_iam_role_policy_attachment.eks_cluster_nodegroup_AmazonEC2ContainerRegistryReadOnly
  ]
}
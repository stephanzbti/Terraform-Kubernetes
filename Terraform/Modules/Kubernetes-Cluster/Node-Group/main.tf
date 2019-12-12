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

resource "aws_iam_role_policy_attachment" "eks_cluster_nodegroup_amazoneksworkernodepolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_cluster_nodegroup_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_nodegroup_amazoneks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_cluster_nodegroup_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_nodegroup_amazonec2containerregistryreadonly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_cluster_nodegroup_role.name
}

resource "aws_eks_node_group" "eks_node_group" {
  count           = length(var.eks_node_group)

  cluster_name    = var.eks_cluster.name
  node_group_name = "EKS-Node-Group"
  node_role_arn   = aws_iam_role.eks_cluster_nodegroup_role.arn
  subnet_ids      = var.eks_node_group[count.index][0].*.id
  instance_types  = var.eks_node_group[count.index][1]

  scaling_config {
    desired_size = var.eks_node_group[count.index][2]
    max_size     = var.eks_node_group[count.index][3]
    min_size     = var.eks_node_group[count.index][4]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_nodegroup_amazoneksworkernodepolicy,
    aws_iam_role_policy_attachment.eks_cluster_nodegroup_amazoneks_cni_policy,
    aws_iam_role_policy_attachment.eks_cluster_nodegroup_amazonec2containerregistryreadonly
  ]
}
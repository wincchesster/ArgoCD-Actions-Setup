resource "aws_eks_cluster" "mycluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    security_group_ids = [aws_security_group.mycluster-cluster.id]
    subnet_ids         = var.subnets_ids
  }

  depends_on = [
    aws_iam_role_policy_attachment.mycluster-cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.mycluster-cluster-AmazonEKSVPCResourceController,
  ]
  tags = merge(local.tags, { Name = var.cluster_name })
}

data "aws_eks_cluster_auth" "mycluster" {
  name = aws_eks_cluster.mycluster.name
}



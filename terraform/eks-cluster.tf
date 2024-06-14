resource "aws_eks_cluster" "mycluster" {
  name     = var.name
  role_arn = aws_iam_role.cluster.arn
  version  = 1.29

  vpc_config {
    security_group_ids = [aws_security_group.mycluster-cluster.id]
    subnet_ids         = module.vpc.private_subnets
  }

  depends_on = [
    aws_iam_role_policy_attachment.mycluster-cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.mycluster-cluster-AmazonEKSVPCResourceController,
  ]
  tags = merge(local.tags, { Name = var.name })
}

data "aws_eks_cluster_auth" "mycluster" {
  name = aws_eks_cluster.mycluster.name
}



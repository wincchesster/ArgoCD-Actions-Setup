# resource "aws_eks_cluster" "mycluster" {
#   name     = var.name
#   role_arn = aws_iam_role.cluster.arn

#   vpc_config {
#     security_group_ids = [aws_security_group.mycluster-cluster.id]
#     subnet_ids         = var.subnets_ids
#   }

#   depends_on = [
#     aws_iam_role_policy_attachment.mycluster-cluster-AmazonEKSClusterPolicy,
#     aws_iam_role_policy_attachment.mycluster-cluster-AmazonEKSVPCResourceController,
#   ]
#   tags = merge(local.tags, { Name = var.name })
# }

# data "aws_eks_cluster_auth" "mycluster" {
#   name = aws_eks_cluster.mycluster.name
# }

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.14.0"

  cluster_name                   = var.name
  cluster_version                = 1.30
  enable_irsa                    = true
  cluster_endpoint_public_access = true
  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  control_plane_subnet_ids       = module.vpc.intra_subnets


  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    eks-external-dns = {
      version = "1.2.0"
      enabled = true
    }
  }

  eks_managed_node_group_defaults = {
    ami_type                              = "AL2_x86_64"
    instance_types                        = ["t2.medium"]
    attach_cluster_primary_security_group = true
  }

  eks_managed_node_groups = {
    mycluster-wg = {
      min_size       = 1
      max_size       = 2
      desired_size   = 1
      instance_types = ["t2.medium"]
      capacity_type  = "SPOT"

      tags = merge(local.tags, { Name = "mycluster-eks-wg" })
    }
  }

  tags = merge(local.tags, { Name = "${var.name}-eks" })
}

output "identity" {
  value = aws_eks_cluster.eks.identity
}







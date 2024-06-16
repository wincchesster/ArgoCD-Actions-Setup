# For cluster
resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-eks-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
  tags               = merge(local.tags, { Name = "${var.cluster_name}-eks-role" })
}

resource "aws_iam_role_policy_attachment" "mycluster-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "mycluster-cluster-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster.name
}

data "tls_certificate" "cert" {
  url = aws_eks_cluster.mycluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "openid_connect" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cert.certificates.0.sha1_fingerprint]
  url             = aws_eks_cluster.mycluster.identity[0].oidc[0].issuer
}


# For nodes
resource "aws_iam_role" "mycluster-node" {
  name = "${var.cluster_name}-eks-node"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
  tags               = merge(local.tags, { Name = "${var.cluster_name}-eks-node" })
}

resource "aws_iam_policy" "secrets_policy" {
  name        = "GetSecrets"
  path        = "/"
  description = "Policy to read aws secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      #{
      #  "Sid" : "AllowListHostedZones",
      #  "Effect" : "Allow",
      #  "Action" : "route53:ChangeResourceRecordSets",
      #  "Resource" : data.aws_route53_zone.mycluster.arn
      #},
      {
        "Sid" : "AllowListHostedZones1",
        "Effect" : "Allow",
        "Action" : [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets",
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "mycluster-node-AmazonSecretsPolicy" {
  policy_arn = aws_iam_policy.secrets_policy.arn
  role       = aws_iam_role.mycluster-node.name
}

resource "aws_iam_role_policy_attachment" "mycluster-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.mycluster-node.name
}

resource "aws_iam_role_policy_attachment" "mycluster-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.mycluster-node.name
}

resource "aws_iam_role_policy_attachment" "mycluster-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.mycluster-node.name
}

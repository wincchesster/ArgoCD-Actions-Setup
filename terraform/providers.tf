# Here we must set our profile, otherwise infra will be created in the root account
provider "aws" {
  region = var.region
}

provider "kubernetes" {
  host                   = aws_eks_cluster.mycluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.mycluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.mycluster.token
}

data "aws_availability_zones" "available" {}


provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.mycluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.mycluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.mycluster.token
  }
}



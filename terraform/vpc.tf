module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.7.1"

  name = "${var.name}-vpc"
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = merge(local.tags, { Name = "${var.name}-vpc" })

}


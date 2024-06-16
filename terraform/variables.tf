variable "cluster_name" {
  description = "value of the name of cluster"
}

variable "region" {
  description = "value of the region"
}

variable "iam_profile" {
  description = "value of the iam profile"
  default     = null
}

variable "hosted_zone_name" {
  description = "value of the hosted zone name"
}

variable "vpc_id" {
  description = "value of the vpc id"
}
variable "subnets_ids" {
  description = "value of the subnets ids"
}

locals {

  vpc_cidr = "10.0.0.0/16"
  azs      = ["eu-central-1a", "eu-central-1b"]

  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]
  intra_subnets   = ["10.0.5.0/24", "10.0.6.0/24"]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }

}




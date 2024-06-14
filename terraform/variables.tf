variable "name" {
  default = "mycluster"
}

variable "region" {
  default = "eu-central-1"
}

variable "iam_profile" {
  default = null
}

variable "hosted_zone_name" {
  default = "step4.space"
}

variable "vpc_id" {
}

variable "subnets_ids" {
}

locals {

  vpc_cidr = "10.0.0.0/16"
  azs      = ["eu-central-1a", "eu-central-1b"]

  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]
  intra_subnets   = ["10.0.5.0/24", "10.0.6.0/24"]

  tags = {
    CreateBy = "Terraform"
  }

}




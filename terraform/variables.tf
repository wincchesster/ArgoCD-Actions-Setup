variable "name" {
  description = "value of the name of cluster"
  type        = string
}

variable "region" {
  description = "value of the region"
  type        = string
}

variable "iam_profile" {
  description = "value of the iam profile"
  default     = null
  type = object({
    name = string
    arn  = string
  })
}

variable "hosted_zone_name" {
  description = "value of the hosted zone name"
  type        = string
}

variable "vpc_id" {
  description = "value of the vpc id"
  type        = string
}
variable "subnets_ids" {
  description = "value of the subnets ids"
  type        = list(string)
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




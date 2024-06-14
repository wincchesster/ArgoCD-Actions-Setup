terraform {
  backend "s3" {
    bucket         = "terraform-states-s3"
    key            = "eks/terraform.tfstate"
    encrypt        = true
    dynamodb_table = "lock-tf-eks"
    region         = "eu-central-1"
    profile        = "default"
  }
}

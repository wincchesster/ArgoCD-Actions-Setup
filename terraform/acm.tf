data "aws_route53_zone" "selected" {
  name         = var.hosted_zone_name
  private_zone = false
}

locals {
  domain_name = "*.mycluster.step4.space"
}


data "aws_acm_certificate" "certificate" {
  domain   = local.domain_name
  statuses = ["ISSUED"]
}

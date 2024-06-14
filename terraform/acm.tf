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

# If the certificate is not found, create it

# resource "aws_acm_certificate" "certificate" {
#   domain_name       = local.domain_name
#   validation_method = "DNS"

#   lifecycle {
#     create_before_destroy = true
#   }

#   tags = local.tags
# }

# resource "aws_acm_certificate_validation" "certificate" {
#   certificate_arn         = aws_acm_certificate.certificate.arn
#   validation_record_fqdns = [for record in aws_acm_certificate.certificate.domain_validation_options : record.resource_record_name]
# }

# resource "aws_route53_record" "certificate_validation" {
#   for_each = { for record in aws_acm_certificate_validation.certificate : record.domain_name => record }

#   zone_id = data.aws_route53_zone.selected.zone_id
#   name    = each.value.resource_record_name
#   type    = each.value.resource_record_type
#   records = [each.value.resource_record_value]
#   ttl     = 60
# }

# output "certificate_arn" {
#   value = aws_acm_certificate.certificate.arn
# }

# output "certificate_validation_record" {
#   value = aws_acm_certificate_validation.certificate
# }

resource "aws_route53_zone" "this" {
  name = var.domain_name
  tags = merge(var.tags, { Name = var.domain_name })
}

# Certificate for CloudFront - MUST live in us-east-1
resource "aws_acm_certificate" "cloudfront" {
  provider = aws.us_east_1

  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"
  tags                      = merge(var.tags, { Name = "${var.domain_name}-cloudfront" })

  lifecycle {
    create_before_destroy = true
  }
}

# Certificate for the ALB - lives in the workload region
resource "aws_acm_certificate" "regional" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"
  tags                      = merge(var.tags, { Name = "${var.domain_name}-alb" })

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  # ACM issues identical validation CNAMEs for the same domain in the same account,
  # so one record set validates both certificates.
  validation_records = {
    for dvo in aws_acm_certificate.cloudfront.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }
}

resource "aws_route53_record" "validation" {
  for_each = local.validation_records

  zone_id         = aws_route53_zone.this.zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = var.validation_record_ttl
  records         = [each.value.record]
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "cloudfront" {
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.cloudfront.arn
  validation_record_fqdns = [for r in aws_route53_record.validation : r.fqdn]
}

resource "aws_acm_certificate_validation" "regional" {
  certificate_arn         = aws_acm_certificate.regional.arn
  validation_record_fqdns = [for r in aws_route53_record.validation : r.fqdn]
}

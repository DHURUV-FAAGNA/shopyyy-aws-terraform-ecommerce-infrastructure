mock_provider "aws" {}

mock_provider "aws" {
  alias = "us_east_1"
}

variables {
  domain_name = "shopyyy.com"
  tags        = { Environment = "test", Project = "shopyyy" }
}

run "hosted_zone_matches_domain" {
  command = plan

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  assert {
    condition     = aws_route53_zone.this.name == "shopyyy.com"
    error_message = "Hosted zone must be for the apex domain."
  }
}

run "certificates_cover_apex_and_wildcard_with_dns_validation" {
  command = plan

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  assert {
    condition     = aws_acm_certificate.cloudfront.domain_name == "shopyyy.com" && contains(aws_acm_certificate.cloudfront.subject_alternative_names, "*.shopyyy.com")
    error_message = "CloudFront cert must cover apex and wildcard."
  }

  assert {
    condition     = aws_acm_certificate.regional.validation_method == "DNS" && aws_acm_certificate.cloudfront.validation_method == "DNS"
    error_message = "Both certificates must use DNS validation."
  }
}

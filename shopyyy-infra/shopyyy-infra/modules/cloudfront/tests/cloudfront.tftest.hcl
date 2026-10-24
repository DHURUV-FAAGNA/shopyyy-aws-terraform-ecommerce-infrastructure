mock_provider "aws" {
  mock_data "aws_cloudfront_cache_policy" {
    defaults = {
      id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    }
  }

  mock_data "aws_cloudfront_origin_request_policy" {
    defaults = {
      id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
    }
  }
}

variables {
  name                           = "test"
  aliases                        = ["shopyyy.com"]
  certificate_arn                = "arn:aws:acm:us-east-1:123456789012:certificate/11111111-2222-3333-4444-555555555555"
  s3_bucket_regional_domain_name = "shopyyy-test-frontend.s3.ap-south-1.amazonaws.com"
  alb_origin_hostname            = "api-origin.shopyyy.com"
  origin_verify_secret           = "test-secret-value"
  tags                           = { Environment = "test", Project = "shopyyy" }
}

run "two_origins_s3_and_alb" {
  command = plan

  assert {
    condition     = length(aws_cloudfront_distribution.this.origin) == 2
    error_message = "Distribution needs exactly two origins."
  }
}

run "api_path_goes_to_alb_everything_else_to_s3" {
  command = plan

  assert {
    condition     = aws_cloudfront_distribution.this.ordered_cache_behavior[0].path_pattern == "/api/*"
    error_message = "/api/* must be a dedicated behavior."
  }

  assert {
    condition     = aws_cloudfront_distribution.this.ordered_cache_behavior[0].target_origin_id == "alb-api"
    error_message = "/api/* must target the ALB origin."
  }

  assert {
    condition     = aws_cloudfront_distribution.this.default_cache_behavior[0].target_origin_id == "s3-frontend"
    error_message = "Default behavior must target S3."
  }
}

run "https_is_enforced_with_acm_certificate" {
  command = plan

  assert {
    condition     = aws_cloudfront_distribution.this.default_cache_behavior[0].viewer_protocol_policy == "redirect-to-https"
    error_message = "Viewers must be redirected to HTTPS."
  }

  assert {
    condition     = aws_cloudfront_distribution.this.viewer_certificate[0].acm_certificate_arn == var.certificate_arn
    error_message = "Must use the ACM certificate."
  }

  assert {
    condition     = aws_cloudfront_distribution.this.viewer_certificate[0].ssl_support_method == "sni-only"
    error_message = "Use SNI-only (no dedicated-IP charge)."
  }
}

run "s3_origin_uses_origin_access_control" {
  command = plan

  assert {
    condition     = aws_cloudfront_origin_access_control.s3.origin_access_control_origin_type == "s3" && aws_cloudfront_origin_access_control.s3.signing_behavior == "always"
    error_message = "OAC must sign all S3 requests."
  }
}

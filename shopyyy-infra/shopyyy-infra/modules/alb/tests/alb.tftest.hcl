mock_provider "aws" {}

variables {
  name                 = "test"
  vpc_id               = "vpc-12345678"
  public_subnet_ids    = ["subnet-aaaaaaaa", "subnet-bbbbbbbb"]
  security_group_id    = "sg-12345678"
  certificate_arn      = "arn:aws:acm:ap-south-1:123456789012:certificate/11111111-2222-3333-4444-555555555555"
  origin_verify_secret = "test-secret-value"
  tags                 = { Environment = "test", Project = "shopyyy" }
}

run "health_check_is_api_health_on_port_3000" {
  command = plan

  assert {
    condition     = aws_lb_target_group.this.health_check[0].path == "/api/health"
    error_message = "Health check path must be /api/health."
  }

  assert {
    condition     = aws_lb_target_group.this.port == 3000 && aws_lb_target_group.this.target_type == "ip"
    error_message = "Target group must be port 3000 with ip targets (Fargate)."
  }
}

run "listener_is_https_443_and_default_denies" {
  command = plan

  assert {
    condition     = aws_lb_listener.https.port == 443 && aws_lb_listener.https.protocol == "HTTPS"
    error_message = "Listener must be HTTPS on 443."
  }

  assert {
    condition     = aws_lb_listener.https.default_action[0].fixed_response[0].status_code == "403"
    error_message = "Requests without the CloudFront header must get 403."
  }
}

run "alb_is_internet_facing_and_hardened" {
  command = plan

  assert {
    condition     = aws_lb.this.internal == false && aws_lb.this.drop_invalid_header_fields == true
    error_message = "ALB must be internet-facing with invalid headers dropped."
  }
}

run "forward_rule_requires_origin_header" {
  command = plan

  assert {
    condition     = one(aws_lb_listener_rule.from_cloudfront.condition).http_header[0].http_header_name == "X-Origin-Verify"
    error_message = "Forward rule must require the origin verification header."
  }
}

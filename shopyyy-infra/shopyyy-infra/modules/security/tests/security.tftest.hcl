mock_provider "aws" {}

variables {
  name                      = "test"
  vpc_id                    = "vpc-12345678"
  cloudfront_prefix_list_id = "pl-3b927c52"
  tags                      = { Environment = "test", Project = "shopyyy" }
}

run "alb_accepts_https_only_from_cloudfront_prefix_list" {
  command = plan

  assert {
    condition     = aws_vpc_security_group_ingress_rule.alb_from_cloudfront.prefix_list_id == var.cloudfront_prefix_list_id
    error_message = "ALB ingress must use the CloudFront prefix list."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.alb_from_cloudfront.from_port == 443
    error_message = "ALB ingress must be port 443."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.alb_from_cloudfront.cidr_ipv4 == null
    error_message = "ALB must not allow any CIDR."
  }
}

run "rds_allows_only_5432_and_only_from_a_security_group" {
  command = plan

  assert {
    condition     = aws_vpc_security_group_ingress_rule.rds_from_ecs.from_port == 5432 && aws_vpc_security_group_ingress_rule.rds_from_ecs.to_port == 5432
    error_message = "RDS ingress must be 5432."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.rds_from_ecs.cidr_ipv4 == null
    error_message = "RDS must not allow CIDR-based ingress."
  }
}

run "redis_allows_only_6379_and_only_from_a_security_group" {
  command = plan

  assert {
    condition     = aws_vpc_security_group_ingress_rule.redis_from_ecs.from_port == 6379
    error_message = "Redis ingress must be 6379."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.redis_from_ecs.cidr_ipv4 == null
    error_message = "Redis must not allow CIDR-based ingress."
  }
}

run "msk_allows_only_9092_and_only_from_a_security_group" {
  command = plan

  assert {
    condition     = aws_vpc_security_group_ingress_rule.msk_from_ecs.from_port == 9092
    error_message = "MSK ingress must be 9092 by default."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.msk_from_ecs.cidr_ipv4 == null
    error_message = "MSK must not allow CIDR-based ingress."
  }
}

run "ecs_accepts_container_port_from_alb_sg_only" {
  command = plan

  assert {
    condition     = aws_vpc_security_group_ingress_rule.ecs_from_alb.from_port == 3000
    error_message = "ECS ingress must be the container port."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.ecs_from_alb.cidr_ipv4 == null
    error_message = "ECS must not allow CIDR-based ingress."
  }
}

run "no_security_group_opens_ingress_to_the_world" {
  command = plan

  assert {
    condition = alltrue([
      for r in [
        aws_vpc_security_group_ingress_rule.alb_from_cloudfront,
        aws_vpc_security_group_ingress_rule.ecs_from_alb,
        aws_vpc_security_group_ingress_rule.rds_from_ecs,
        aws_vpc_security_group_ingress_rule.redis_from_ecs,
        aws_vpc_security_group_ingress_rule.msk_from_ecs,
      ] : r.cidr_ipv4 != "0.0.0.0/0"
    ])
    error_message = "No ingress rule may allow 0.0.0.0/0."
  }
}

run "kafka_port_follows_variable_for_tls" {
  command = plan

  variables {
    kafka_port = 9098
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.msk_from_ecs.from_port == 9098 && aws_vpc_security_group_egress_rule.ecs_to_msk.from_port == 9098
    error_message = "MSK rules must follow kafka_port."
  }
}

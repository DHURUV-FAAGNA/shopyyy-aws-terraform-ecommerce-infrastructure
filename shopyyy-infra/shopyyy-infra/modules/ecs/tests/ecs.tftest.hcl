mock_provider "aws" {}

variables {
  name               = "test"
  environment        = "test"
  region             = "ap-south-1"
  private_subnet_ids = ["subnet-aaaaaaaa", "subnet-bbbbbbbb"]
  security_group_id  = "sg-12345678"
  target_group_arn   = "arn:aws:elasticloadbalancing:ap-south-1:123456789012:targetgroup/test/abcdef1234567890"
  db_host            = "db.example.internal"
  db_port            = 5432
  db_name            = "shopyyy"
  db_secret_arn      = "arn:aws:secretsmanager:ap-south-1:123456789012:secret:rds-abc123"
  redis_url          = "rediss://redis.example.internal:6379"
  kafka_brokers      = "b-1.example:9092,b-2.example:9092"
  tags               = { Environment = "test", Project = "shopyyy" }
}

run "api_service_runs_two_tasks_on_fargate_in_private_subnets" {
  command = plan

  assert {
    condition     = aws_ecs_service.this["api"].desired_count == 2
    error_message = "API service must run 2 tasks."
  }

  assert {
    condition     = aws_ecs_service.this["api"].launch_type == "FARGATE"
    error_message = "Service must use Fargate."
  }

  assert {
    condition     = length(aws_ecs_service.this["api"].network_configuration[0].subnets) == 2
    error_message = "Tasks must span two subnets (two AZs)."
  }

  assert {
    condition     = aws_ecs_service.this["api"].network_configuration[0].assign_public_ip == false
    error_message = "Tasks must not get public IPs."
  }
}

run "container_listens_on_3000_and_gets_secrets_from_secrets_manager" {
  command = plan

  assert {
    condition     = jsondecode(aws_ecs_task_definition.this["api"].container_definitions)[0].portMappings[0].containerPort == 3000
    error_message = "Container port must be 3000."
  }

  assert {
    condition     = contains([for s in jsondecode(aws_ecs_task_definition.this["api"].container_definitions)[0].secrets : s.name], "DB_PASSWORD")
    error_message = "DB password must come from Secrets Manager."
  }

  assert {
    condition     = contains([for e in jsondecode(aws_ecs_task_definition.this["api"].container_definitions)[0].environment : e.name], "REDIS_URL")
    error_message = "REDIS_URL must be injected."
  }
}

run "no_plaintext_password_in_environment" {
  command = plan

  assert {
    condition     = !contains([for e in jsondecode(aws_ecs_task_definition.this["api"].container_definitions)[0].environment : e.name], "DB_PASSWORD")
    error_message = "Password must never be a plain environment variable."
  }
}

run "worker_service_is_off_by_default" {
  command = plan

  assert {
    condition     = length(aws_ecs_service.this) == 1
    error_message = "Only the API service should exist by default."
  }
}

run "worker_service_created_when_enabled" {
  command = plan

  variables {
    worker_enabled = true
  }

  assert {
    condition     = contains(keys(aws_ecs_service.this), "worker")
    error_message = "Worker service expected when enabled."
  }
}

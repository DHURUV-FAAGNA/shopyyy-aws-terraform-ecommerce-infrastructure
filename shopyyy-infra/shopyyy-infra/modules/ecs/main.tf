locals {
  services = merge(
    {
      api = {
        command       = var.container_command
        desired_count = var.desired_count
        has_lb        = true
      }
    },
    var.worker_enabled ? {
      worker = {
        command       = var.worker_command
        desired_count = var.worker_desired_count
        has_lb        = false
      }
    } : {}
  )

  environment = [
    { name = "NODE_ENV", value = var.environment },
    { name = "PORT", value = tostring(var.container_port) },
    { name = "DB_HOST", value = var.db_host },
    { name = "DB_PORT", value = tostring(var.db_port) },
    { name = "DB_NAME", value = var.db_name },
    { name = "REDIS_URL", value = var.redis_url },
    { name = "KAFKA_BROKERS", value = var.kafka_brokers },
  ]

  # Pull individual JSON keys out of the RDS-managed secret
  secrets = [
    { name = "DB_USERNAME", valueFrom = "${var.db_secret_arn}:username::" },
    { name = "DB_PASSWORD", valueFrom = "${var.db_secret_arn}:password::" },
  ]

  ecs_tasks_assume_role = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_ecs_cluster" "this" {
  name = "${var.name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(var.tags, { Name = "${var.name}-cluster" })
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.name}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

# Execution role: used by ECS itself (pull image, write logs, read secrets)
resource "aws_iam_role" "execution" {
  name               = "${var.name}-ecs-execution"
  assume_role_policy = local.ecs_tasks_assume_role
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "execution_managed" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "execution_secrets" {
  name = "read-db-secret"
  role = aws_iam_role.execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = [var.db_secret_arn]
    }]
  })
}

# Task role: identity of the application code (kept empty = least privilege; add permissions as needed)
resource "aws_iam_role" "task" {
  name               = "${var.name}-ecs-task"
  assume_role_policy = local.ecs_tasks_assume_role
  tags               = var.tags
}

resource "aws_ecs_task_definition" "this" {
  for_each = local.services

  family                   = "${var.name}-${each.key}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    merge(
      {
        name        = each.key
        image       = var.container_image
        essential   = true
        environment = local.environment
        secrets     = local.secrets
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            "awslogs-group"         = aws_cloudwatch_log_group.this.name
            "awslogs-region"        = var.region
            "awslogs-stream-prefix" = each.key
          }
        }
      },
      each.value.has_lb ? { portMappings = [{ containerPort = var.container_port, protocol = "tcp" }] } : {},
      length(each.value.command) > 0 ? { command = each.value.command } : {}
    )
  ])

  tags = merge(var.tags, { Name = "${var.name}-${each.key}" })
}

resource "aws_ecs_service" "this" {
  for_each = local.services

  name            = "${var.name}-${each.key}"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this[each.key].arn
  desired_count   = each.value.desired_count
  launch_type     = "FARGATE"

  # Fargate balances tasks across the subnets (one per AZ) automatically
  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.security_group_id]
    assign_public_ip = false
  }

  dynamic "load_balancer" {
    for_each = each.value.has_lb ? [1] : []

    content {
      target_group_arn = var.target_group_arn
      container_name   = each.key
      container_port   = var.container_port
    }
  }

  health_check_grace_period_seconds = each.value.has_lb ? 60 : null

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  tags = merge(var.tags, { Name = "${var.name}-${each.key}" })
}

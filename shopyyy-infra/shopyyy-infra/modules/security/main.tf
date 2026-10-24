resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "ALB: HTTPS from CloudFront only"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name}-alb-sg" })
}

resource "aws_security_group" "ecs" {
  name        = "${var.name}-ecs-sg"
  description = "ECS tasks: traffic from ALB only"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name}-ecs-sg" })
}

resource "aws_security_group" "rds" {
  name        = "${var.name}-rds-sg"
  description = "RDS PostgreSQL: from ECS only"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name}-rds-sg" })
}

resource "aws_security_group" "redis" {
  name        = "${var.name}-redis-sg"
  description = "ElastiCache Redis: from ECS only"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name}-redis-sg" })
}

resource "aws_security_group" "msk" {
  name        = "${var.name}-msk-sg"
  description = "MSK Kafka: from ECS only"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name}-msk-sg" })
}

# ---- ALB ----
resource "aws_vpc_security_group_ingress_rule" "alb_from_cloudfront" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from CloudFront origin-facing prefix list"
  prefix_list_id    = var.cloudfront_prefix_list_id
  from_port         = var.alb_listener_port
  to_port           = var.alb_listener_port
  ip_protocol       = "tcp"
  tags              = var.tags
}

resource "aws_vpc_security_group_egress_rule" "alb_to_ecs" {
  security_group_id            = aws_security_group.alb.id
  description                  = "To ECS tasks"
  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = var.container_port
  to_port                      = var.container_port
  ip_protocol                  = "tcp"
  tags                         = var.tags
}

# ---- ECS ----
resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id            = aws_security_group.ecs.id
  description                  = "From ALB"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.container_port
  to_port                      = var.container_port
  ip_protocol                  = "tcp"
  tags                         = var.tags
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_rds" {
  security_group_id            = aws_security_group.ecs.id
  description                  = "To RDS"
  referenced_security_group_id = aws_security_group.rds.id
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
  tags                         = var.tags
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_redis" {
  security_group_id            = aws_security_group.ecs.id
  description                  = "To ElastiCache"
  referenced_security_group_id = aws_security_group.redis.id
  from_port                    = var.redis_port
  to_port                      = var.redis_port
  ip_protocol                  = "tcp"
  tags                         = var.tags
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_msk" {
  security_group_id            = aws_security_group.ecs.id
  description                  = "To MSK"
  referenced_security_group_id = aws_security_group.msk.id
  from_port                    = var.kafka_port
  to_port                      = var.kafka_port
  ip_protocol                  = "tcp"
  tags                         = var.tags
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_internet_https" {
  security_group_id = aws_security_group.ecs.id
  description       = "HTTPS out via NAT (ECR image pull, Secrets Manager, CloudWatch)"
  cidr_ipv4         = var.internet_cidr
  from_port         = var.https_port
  to_port           = var.https_port
  ip_protocol       = "tcp"
  tags              = var.tags
}

# ---- Data stores: inbound from ECS SG only ----
resource "aws_vpc_security_group_ingress_rule" "rds_from_ecs" {
  security_group_id            = aws_security_group.rds.id
  description                  = "PostgreSQL from ECS"
  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
  tags                         = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "redis_from_ecs" {
  security_group_id            = aws_security_group.redis.id
  description                  = "Redis from ECS"
  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = var.redis_port
  to_port                      = var.redis_port
  ip_protocol                  = "tcp"
  tags                         = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "msk_from_ecs" {
  security_group_id            = aws_security_group.msk.id
  description                  = "Kafka from ECS"
  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = var.kafka_port
  to_port                      = var.kafka_port
  ip_protocol                  = "tcp"
  tags                         = var.tags
}

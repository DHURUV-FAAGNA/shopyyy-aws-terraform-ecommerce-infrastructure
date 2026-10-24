data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = var.cloudfront_prefix_list_name
}

locals {
  name = lower("${var.project}-${var.environment}")

  tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }

  azs             = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  origin_hostname = "${var.origin_subdomain}.${var.domain_name}"
  kafka_port      = var.msk_client_broker_encryption == "PLAINTEXT" ? var.kafka_plaintext_port : var.kafka_tls_port
}

# Shared secret: CloudFront sends it, the ALB only forwards requests that carry it
resource "random_password" "origin_verify" {
  length  = 40
  special = false
}

# ---------------- networking ----------------
module "network" {
  source = "../../modules/network"

  name               = local.name
  vpc_cidr           = var.vpc_cidr
  availability_zones = local.azs
  single_nat_gateway = var.single_nat_gateway
  tags               = local.tags
}

module "security" {
  source = "../../modules/security"

  name                      = local.name
  vpc_id                    = module.network.vpc_id
  cloudfront_prefix_list_id = data.aws_ec2_managed_prefix_list.cloudfront.id
  container_port            = var.container_port
  db_port                   = var.db_port
  redis_port                = var.redis_port
  kafka_port                = local.kafka_port
  tags                      = local.tags
}

# ---------------- DNS + certificates ----------------
module "dns_acm" {
  source = "../../modules/dns_acm"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  domain_name = var.domain_name
  tags        = local.tags
}

# ---------------- data layer ----------------
module "rds" {
  source = "../../modules/rds"

  name                = local.name
  private_subnet_ids  = module.network.private_subnet_ids
  security_group_id   = module.security.rds_sg_id
  engine_version      = var.rds_engine_version
  instance_class      = var.rds_instance_class
  db_name             = var.rds_db_name
  port                = var.db_port
  multi_az            = var.rds_multi_az
  deletion_protection = var.rds_deletion_protection
  skip_final_snapshot = var.rds_skip_final_snapshot
  tags                = local.tags
}

module "redis" {
  source = "../../modules/redis"

  name               = local.name
  private_subnet_ids = module.network.private_subnet_ids
  security_group_id  = module.security.redis_sg_id
  node_type          = var.redis_node_type
  port               = var.redis_port
  tags               = local.tags
}

module "msk" {
  source = "../../modules/msk"

  name                     = local.name
  private_subnet_ids       = module.network.private_subnet_ids
  security_group_id        = module.security.msk_sg_id
  broker_count             = var.msk_broker_count
  broker_instance_type     = var.msk_broker_instance_type
  client_broker_encryption = var.msk_client_broker_encryption
  tags                     = local.tags
}

# ---------------- edge: ALB, S3, CloudFront ----------------
module "alb" {
  source = "../../modules/alb"

  name                 = local.name
  vpc_id               = module.network.vpc_id
  public_subnet_ids    = module.network.public_subnet_ids
  security_group_id    = module.security.alb_sg_id
  certificate_arn      = module.dns_acm.regional_certificate_arn
  container_port       = var.container_port
  health_check_path    = var.health_check_path
  origin_verify_secret = random_password.origin_verify.result
  deletion_protection  = var.alb_deletion_protection
  tags                 = local.tags
}

module "frontend_bucket" {
  source = "../../modules/s3_frontend"

  bucket_name                 = "${local.name}-frontend-${data.aws_caller_identity.current.account_id}"
  cloudfront_distribution_arn = module.cloudfront.arn
  force_destroy               = var.frontend_force_destroy
  tags                        = local.tags
}

module "cloudfront" {
  source = "../../modules/cloudfront"

  name                           = local.name
  aliases                        = [var.domain_name]
  certificate_arn                = module.dns_acm.cloudfront_certificate_arn
  s3_bucket_regional_domain_name = module.frontend_bucket.bucket_regional_domain_name
  alb_origin_hostname            = local.origin_hostname
  origin_verify_secret           = random_password.origin_verify.result
  tags                           = local.tags
}

module "dns_records" {
  source = "../../modules/dns_records"

  zone_id                = module.dns_acm.zone_id
  domain_name            = var.domain_name
  cloudfront_domain_name = module.cloudfront.domain_name
  cloudfront_zone_id     = module.cloudfront.hosted_zone_id
  origin_hostname        = local.origin_hostname
  alb_dns_name           = module.alb.dns_name
  alb_zone_id            = module.alb.zone_id
}

# ---------------- compute ----------------
module "ecs" {
  source = "../../modules/ecs"

  name               = local.name
  environment        = var.environment
  region             = var.region
  private_subnet_ids = module.network.private_subnet_ids
  security_group_id  = module.security.ecs_sg_id
  target_group_arn   = module.alb.target_group_arn
  container_image    = var.container_image
  container_command  = var.container_command
  container_port     = var.container_port
  cpu                = var.task_cpu
  memory             = var.task_memory
  desired_count      = var.ecs_desired_count
  worker_enabled     = var.worker_enabled
  db_host            = module.rds.address
  db_port            = module.rds.port
  db_name            = module.rds.db_name
  db_secret_arn      = module.rds.master_secret_arn
  redis_url          = module.redis.url
  kafka_brokers      = module.msk.bootstrap_brokers
  tags               = local.tags

  # The target group must be attached to a listener before the service registers with it
  depends_on = [module.alb]
}

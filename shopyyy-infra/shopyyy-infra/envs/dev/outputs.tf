output "cloudfront_domain_name" {
  description = "CloudFront distribution domain."
  value       = module.cloudfront.domain_name
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name."
  value       = module.alb.dns_name
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint (host:port)."
  value       = module.rds.endpoint
}

output "redis_endpoint" {
  description = "ElastiCache Redis primary endpoint."
  value       = module.redis.endpoint
}

output "kafka_bootstrap_brokers" {
  value = module.msk.bootstrap_brokers
}

output "db_secret_arn" {
  description = "Secrets Manager ARN holding DB credentials."
  value       = module.rds.master_secret_arn
}

output "name_servers" {
  description = "Point your registrar's NS records here so ACM validation can complete."
  value       = module.dns_acm.name_servers
}

output "frontend_bucket" {
  value = module.frontend_bucket.bucket_id
}

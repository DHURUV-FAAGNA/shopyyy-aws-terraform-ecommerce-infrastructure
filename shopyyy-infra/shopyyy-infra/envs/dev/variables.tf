# ---------- general ----------
variable "project" {
  type    = string
  default = "shopyyy"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "cloudfront_certificate_region" {
  description = "Region CloudFront requires for its ACM certificate."
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  type    = string
  default = "shopyyy.com"
}

variable "origin_subdomain" {
  description = "Subdomain CloudFront uses to reach the ALB (covered by the wildcard cert)."
  type        = string
  default     = "api-origin"
}

# ---------- networking ----------
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "az_count" {
  type    = number
  default = 2
}

variable "single_nat_gateway" {
  type    = bool
  default = true
}

# ---------- security / ports ----------
variable "cloudfront_prefix_list_name" {
  type    = string
  default = "com.amazonaws.global.cloudfront.origin-facing"
}

variable "container_port" {
  type    = number
  default = 3000
}

variable "health_check_path" {
  type    = string
  default = "/api/health"
}

variable "db_port" {
  type    = number
  default = 5432
}

variable "redis_port" {
  type    = number
  default = 6379
}

variable "kafka_plaintext_port" {
  type    = number
  default = 9092
}

variable "kafka_tls_port" {
  type    = number
  default = 9098
}

# ---------- compute ----------
variable "container_image" {
  type    = string
  default = "hashicorp/http-echo:1.0"
}

variable "container_command" {
  type    = list(string)
  default = ["-listen=:3000", "-text=ok"]
}

variable "task_cpu" {
  type    = number
  default = 256
}

variable "task_memory" {
  type    = number
  default = 512
}

variable "ecs_desired_count" {
  type    = number
  default = 2
}

variable "worker_enabled" {
  type    = bool
  default = false
}

# ---------- data stores ----------
variable "rds_instance_class" {
  type    = string
  default = "db.t3.medium"
}

variable "rds_engine_version" {
  type    = string
  default = "17"
}

variable "rds_multi_az" {
  type    = bool
  default = true
}

variable "rds_db_name" {
  type    = string
  default = "shopyyy"
}

variable "rds_deletion_protection" {
  type    = bool
  default = false
}

variable "rds_skip_final_snapshot" {
  type    = bool
  default = true
}

variable "redis_node_type" {
  type    = string
  default = "cache.t3.micro"
}

variable "msk_broker_count" {
  type    = number
  default = 2
}

variable "msk_broker_instance_type" {
  type    = string
  default = "kafka.t3.small"
}

variable "msk_client_broker_encryption" {
  description = "PLAINTEXT (9092, as the brief specifies) or TLS (IAM auth, 9098 - recommended for prod)."
  type        = string
  default     = "PLAINTEXT"
}

# ---------- misc ----------
variable "frontend_force_destroy" {
  type    = bool
  default = true
}

variable "alb_deletion_protection" {
  type    = bool
  default = false
}

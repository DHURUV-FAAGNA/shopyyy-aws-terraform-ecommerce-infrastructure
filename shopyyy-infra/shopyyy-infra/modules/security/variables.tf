variable "name" {
  description = "Name prefix."
  type        = string
}

variable "vpc_id" {
  description = "VPC the security groups live in."
  type        = string
}

variable "cloudfront_prefix_list_id" {
  description = "AWS managed prefix list ID for CloudFront origin-facing IPs."
  type        = string
}

variable "alb_listener_port" {
  type    = number
  default = 443
}

variable "container_port" {
  type    = number
  default = 3000
}

variable "db_port" {
  type    = number
  default = 5432
}

variable "redis_port" {
  type    = number
  default = 6379
}

variable "kafka_port" {
  description = "9092 = plaintext, 9098 = TLS + IAM auth."
  type        = number
  default     = 9092
}

variable "https_port" {
  description = "Outbound HTTPS from ECS (image pulls, AWS APIs) via NAT."
  type        = number
  default     = 443
}

variable "internet_cidr" {
  description = "CIDR used for the ECS outbound-to-internet rule."
  type        = string
  default     = "0.0.0.0/0"
}

variable "tags" {
  type    = map(string)
  default = {}
}

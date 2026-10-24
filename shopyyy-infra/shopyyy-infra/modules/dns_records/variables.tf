variable "zone_id" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "cloudfront_domain_name" {
  type = string
}

variable "cloudfront_zone_id" {
  type = string
}

variable "origin_hostname" {
  description = "Hostname CloudFront uses to reach the ALB (must match the ACM wildcard), e.g. api-origin.shopyyy.com."
  type        = string
}

variable "alb_dns_name" {
  type = string
}

variable "alb_zone_id" {
  type = string
}

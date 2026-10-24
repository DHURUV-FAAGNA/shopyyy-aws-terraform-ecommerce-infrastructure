variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "security_group_id" {
  type = string
}

variable "certificate_arn" {
  description = "Regional ACM certificate for the HTTPS listener."
  type        = string
}

variable "listener_port" {
  type    = number
  default = 443
}

variable "container_port" {
  type    = number
  default = 3000
}

variable "health_check_path" {
  type    = string
  default = "/api/health"
}

variable "ssl_policy" {
  type    = string
  default = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "origin_verify_header_name" {
  description = "Header CloudFront adds; the ALB rejects requests without it."
  type        = string
  default     = "X-Origin-Verify"
}

variable "origin_verify_secret" {
  description = "Shared secret value for the origin verification header."
  type        = string
  sensitive   = true
}

variable "deletion_protection" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}

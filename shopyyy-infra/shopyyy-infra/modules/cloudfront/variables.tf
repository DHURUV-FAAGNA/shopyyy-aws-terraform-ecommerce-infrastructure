variable "name" {
  type = string
}

variable "aliases" {
  description = "Domain names served by the distribution."
  type        = list(string)
}

variable "certificate_arn" {
  description = "ACM certificate in us-east-1."
  type        = string
}

variable "s3_bucket_regional_domain_name" {
  type = string
}

variable "alb_origin_hostname" {
  description = "DNS name of the ALB origin; must be covered by the certificate on the ALB."
  type        = string
}

variable "origin_verify_header_name" {
  type    = string
  default = "X-Origin-Verify"
}

variable "origin_verify_secret" {
  type      = string
  sensitive = true
}

variable "api_path_pattern" {
  type    = string
  default = "/api/*"
}

variable "default_root_object" {
  type    = string
  default = "index.html"
}

variable "price_class" {
  type    = string
  default = "PriceClass_100"
}

variable "minimum_tls_version" {
  type    = string
  default = "TLSv1.2_2021"
}

variable "tags" {
  type    = map(string)
  default = {}
}

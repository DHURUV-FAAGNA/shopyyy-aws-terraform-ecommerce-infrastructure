output "zone_id" {
  value = aws_route53_zone.this.zone_id
}

output "name_servers" {
  description = "Set these at your domain registrar."
  value       = aws_route53_zone.this.name_servers
}

output "cloudfront_certificate_arn" {
  description = "Validated us-east-1 certificate for CloudFront."
  value       = aws_acm_certificate_validation.cloudfront.certificate_arn
}

output "regional_certificate_arn" {
  description = "Validated regional certificate for the ALB."
  value       = aws_acm_certificate_validation.regional.certificate_arn
}

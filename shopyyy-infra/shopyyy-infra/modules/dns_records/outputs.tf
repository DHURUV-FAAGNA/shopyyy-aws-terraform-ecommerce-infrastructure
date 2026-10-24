output "site_fqdn" {
  value = aws_route53_record.site_a.fqdn
}

output "origin_fqdn" {
  value = aws_route53_record.alb_origin.fqdn
}

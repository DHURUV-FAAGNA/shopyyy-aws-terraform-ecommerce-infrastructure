output "endpoint" {
  value = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "port" {
  value = var.port
}

output "url" {
  description = "TLS connection URL (rediss://) - transit encryption is enabled."
  value       = "rediss://${aws_elasticache_replication_group.this.primary_endpoint_address}:${var.port}"
}

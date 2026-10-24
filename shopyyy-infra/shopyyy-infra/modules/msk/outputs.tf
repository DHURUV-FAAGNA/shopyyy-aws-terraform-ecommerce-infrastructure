output "bootstrap_brokers" {
  description = "Bootstrap string matching the chosen encryption mode."
  value       = var.client_broker_encryption == "PLAINTEXT" ? aws_msk_cluster.this.bootstrap_brokers : aws_msk_cluster.this.bootstrap_brokers_sasl_iam
}

output "arn" {
  value = aws_msk_cluster.this.arn
}

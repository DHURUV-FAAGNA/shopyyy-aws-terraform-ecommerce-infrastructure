variable "name" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "security_group_id" {
  type = string
}

variable "kafka_version" {
  type    = string
  default = "3.6.0"
}

variable "broker_count" {
  type    = number
  default = 2
}

variable "broker_instance_type" {
  type    = string
  default = "kafka.t3.small"
}

variable "broker_volume_size" {
  type    = number
  default = 20
}

variable "client_broker_encryption" {
  description = "PLAINTEXT (port 9092, as the brief requires) or TLS + IAM auth (port 9098, recommended for production)."
  type        = string
  default     = "PLAINTEXT"

  validation {
    condition     = contains(["PLAINTEXT", "TLS"], var.client_broker_encryption)
    error_message = "client_broker_encryption must be PLAINTEXT or TLS."
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}

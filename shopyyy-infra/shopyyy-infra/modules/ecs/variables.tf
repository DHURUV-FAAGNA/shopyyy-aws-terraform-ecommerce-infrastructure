variable "name" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "security_group_id" {
  type = string
}

variable "target_group_arn" {
  type = string
}

variable "container_image" {
  description = "Placeholder image until the real API image is pushed to ECR."
  type        = string
  default     = "hashicorp/http-echo:1.0"
}

variable "container_command" {
  description = "Command for the placeholder image. Empty = use the image's default CMD."
  type        = list(string)
  default     = ["-listen=:3000", "-text=ok"]
}

variable "container_port" {
  type    = number
  default = 3000
}

variable "cpu" {
  type    = number
  default = 256
}

variable "memory" {
  type    = number
  default = 512
}

variable "desired_count" {
  type    = number
  default = 2
}

variable "db_host" {
  type = string
}

variable "db_port" {
  type = number
}

variable "db_name" {
  type = string
}

variable "db_secret_arn" {
  description = "Secrets Manager secret (RDS managed) holding username and password."
  type        = string
}

variable "redis_url" {
  type = string
}

variable "kafka_brokers" {
  type = string
}

variable "log_retention_days" {
  type    = number
  default = 14
}

variable "worker_enabled" {
  description = "Run a second service that consumes orders from Kafka."
  type        = bool
  default     = false
}

variable "worker_command" {
  type    = list(string)
  default = ["node", "worker.js"]
}

variable "worker_desired_count" {
  type    = number
  default = 1
}

variable "tags" {
  type    = map(string)
  default = {}
}

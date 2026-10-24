variable "domain_name" {
  description = "Apex domain, e.g. shopyyy.com."
  type        = string
}

variable "validation_record_ttl" {
  type    = number
  default = 60
}

variable "tags" {
  type    = map(string)
  default = {}
}

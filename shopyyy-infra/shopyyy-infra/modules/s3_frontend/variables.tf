variable "bucket_name" {
  description = "Globally unique bucket name."
  type        = string
}

variable "cloudfront_distribution_arn" {
  description = "Only this distribution may read objects."
  type        = string
}

variable "force_destroy" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}

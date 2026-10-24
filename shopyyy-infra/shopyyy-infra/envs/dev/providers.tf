provider "aws" {
  region = var.region

  default_tags {
    tags = local.tags
  }
}

# CloudFront only accepts ACM certificates issued in us-east-1
provider "aws" {
  alias  = "us_east_1"
  region = var.cloudfront_certificate_region

  default_tags {
    tags = local.tags
  }
}

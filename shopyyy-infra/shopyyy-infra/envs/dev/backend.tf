# Partial backend configuration: bucket/key/region are supplied at init time so nothing is hardcoded.
#   terraform init -backend-config=backend.hcl      (see backend.hcl.example)
terraform {
  backend "s3" {}
}

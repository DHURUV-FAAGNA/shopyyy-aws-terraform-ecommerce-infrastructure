mock_provider "aws" {}

variables {
  bucket_name                 = "shopyyy-test-frontend-123456789012"
  cloudfront_distribution_arn = "arn:aws:cloudfront::123456789012:distribution/EABCDEFGHIJKL"
  tags                        = { Environment = "test", Project = "shopyyy" }
}

run "all_four_public_access_blocks_enabled" {
  command = plan

  assert {
    condition = alltrue([
      aws_s3_bucket_public_access_block.this.block_public_acls,
      aws_s3_bucket_public_access_block.this.block_public_policy,
      aws_s3_bucket_public_access_block.this.ignore_public_acls,
      aws_s3_bucket_public_access_block.this.restrict_public_buckets,
    ])
    error_message = "Every S3 public access block setting must be true."
  }
}

run "policy_allows_only_cloudfront_service_for_the_given_distribution" {
  command = plan

  assert {
    condition     = jsondecode(aws_s3_bucket_policy.this.policy).Statement[0].Principal.Service == "cloudfront.amazonaws.com"
    error_message = "Only the CloudFront service principal may read."
  }

  assert {
    condition     = jsondecode(aws_s3_bucket_policy.this.policy).Statement[0].Condition.StringEquals["AWS:SourceArn"] == var.cloudfront_distribution_arn
    error_message = "Access must be scoped to the distribution ARN."
  }

  assert {
    condition     = jsondecode(aws_s3_bucket_policy.this.policy).Statement[0].Action == "s3:GetObject"
    error_message = "Read-only access required."
  }
}

run "bucket_is_versioned_and_encrypted" {
  command = plan

  assert {
    condition     = aws_s3_bucket_versioning.this.versioning_configuration[0].status == "Enabled"
    error_message = "Versioning must be enabled."
  }

  assert {
    condition     = one(one(aws_s3_bucket_server_side_encryption_configuration.this.rule).apply_server_side_encryption_by_default).sse_algorithm == "AES256"
    error_message = "Server-side encryption must be enabled."
  }
}

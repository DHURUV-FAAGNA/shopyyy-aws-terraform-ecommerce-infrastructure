mock_provider "aws" {}

variables {
  name               = "test"
  private_subnet_ids = ["subnet-aaaaaaaa", "subnet-bbbbbbbb"]
  security_group_id  = "sg-12345678"
  tags               = { Environment = "test", Project = "shopyyy" }
}

run "single_t3_micro_redis_node" {
  command = plan

  assert {
    condition     = aws_elasticache_replication_group.this.node_type == "cache.t3.micro"
    error_message = "Node type must be cache.t3.micro."
  }

  assert {
    condition     = aws_elasticache_replication_group.this.num_cache_clusters == 1
    error_message = "Single node expected."
  }
}

run "encrypted_and_attached_to_the_given_sg_and_subnet_group" {
  command = plan

  assert {
    condition     = tostring(aws_elasticache_replication_group.this.at_rest_encryption_enabled) == "true" && aws_elasticache_replication_group.this.transit_encryption_enabled == true
    error_message = "Encryption at rest and in transit must be enabled."
  }

  assert {
    condition     = contains(aws_elasticache_replication_group.this.security_group_ids, var.security_group_id)
    error_message = "Redis must use the dedicated security group."
  }

  assert {
    condition     = length(aws_elasticache_subnet_group.this.subnet_ids) == 2
    error_message = "Subnet group must hold the private subnets."
  }
}

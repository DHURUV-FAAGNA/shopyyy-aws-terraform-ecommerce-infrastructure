mock_provider "aws" {}

variables {
  name               = "test"
  private_subnet_ids = ["subnet-aaaaaaaa", "subnet-bbbbbbbb"]
  security_group_id  = "sg-12345678"
  tags               = { Environment = "test", Project = "shopyyy" }
}

run "two_brokers_in_two_private_subnets" {
  command = plan

  assert {
    condition     = aws_msk_cluster.this.number_of_broker_nodes == 2
    error_message = "Two brokers required."
  }

  assert {
    condition     = length(aws_msk_cluster.this.broker_node_group_info[0].client_subnets) == 2
    error_message = "Brokers must span two subnets."
  }
}

run "uses_dedicated_security_group" {
  command = plan

  assert {
    condition     = contains(aws_msk_cluster.this.broker_node_group_info[0].security_groups, var.security_group_id)
    error_message = "MSK must use the MSK security group."
  }
}

run "tls_mode_disables_unauthenticated_access" {
  command = plan

  variables {
    client_broker_encryption = "TLS"
  }

  assert {
    condition     = aws_msk_cluster.this.client_authentication[0].unauthenticated == false
    error_message = "TLS mode must not allow unauthenticated clients."
  }
}

run "rejects_invalid_encryption_mode" {
  command = plan

  variables {
    client_broker_encryption = "NONE"
  }

  expect_failures = [var.client_broker_encryption]
}

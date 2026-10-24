mock_provider "aws" {}

variables {
  name               = "test"
  private_subnet_ids = ["subnet-aaaaaaaa", "subnet-bbbbbbbb"]
  security_group_id  = "sg-12345678"
  tags               = { Environment = "test", Project = "shopyyy" }
}

run "multi_az_and_not_public" {
  command = plan

  assert {
    condition     = aws_db_instance.this.multi_az == true
    error_message = "RDS must be Multi-AZ."
  }

  assert {
    condition     = aws_db_instance.this.publicly_accessible == false
    error_message = "RDS must not be publicly accessible."
  }
}

run "postgres_17_on_t3_medium" {
  command = plan

  assert {
    condition     = aws_db_instance.this.engine == "postgres" && startswith(aws_db_instance.this.engine_version, "17")
    error_message = "Engine must be PostgreSQL 17."
  }

  assert {
    condition     = aws_db_instance.this.instance_class == "db.t3.medium"
    error_message = "Instance class must be db.t3.medium."
  }
}

run "credentials_managed_by_secrets_manager" {
  command = plan

  assert {
    condition     = aws_db_instance.this.manage_master_user_password == true
    error_message = "Master password must be managed by Secrets Manager."
  }

  assert {
    condition     = aws_db_instance.this.password == null
    error_message = "No password may be set in code."
  }
}

run "storage_is_encrypted" {
  command = plan

  assert {
    condition     = aws_db_instance.this.storage_encrypted == true
    error_message = "Storage must be encrypted."
  }
}

run "uses_private_subnet_group" {
  command = plan

  assert {
    condition     = length(aws_db_subnet_group.this.subnet_ids) == 2
    error_message = "Subnet group must contain both private subnets."
  }
}

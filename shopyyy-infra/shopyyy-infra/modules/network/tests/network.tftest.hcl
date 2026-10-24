mock_provider "aws" {}

variables {
  name               = "test"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["ap-south-1a", "ap-south-1b"]
  tags               = { Environment = "test", Project = "shopyyy" }
}

run "two_public_and_two_private_subnets" {
  command = plan

  assert {
    condition     = length(aws_subnet.public) == 2 && length(aws_subnet.private) == 2
    error_message = "Expected 2 public and 2 private subnets."
  }
}

run "subnets_are_in_different_azs" {
  command = plan

  assert {
    condition     = aws_subnet.public[0].availability_zone != aws_subnet.public[1].availability_zone
    error_message = "Public subnets must be in different AZs."
  }

  assert {
    condition     = aws_subnet.private[0].availability_zone != aws_subnet.private[1].availability_zone
    error_message = "Private subnets must be in different AZs."
  }
}

run "subnet_cidrs_are_derived_and_do_not_overlap" {
  command = plan

  assert {
    condition     = length(distinct(concat(aws_subnet.public[*].cidr_block, aws_subnet.private[*].cidr_block))) == 4
    error_message = "Subnet CIDRs must be unique."
  }
}

run "vpc_uses_cidr_variable" {
  command = plan

  assert {
    condition     = aws_vpc.this.cidr_block == var.vpc_cidr
    error_message = "VPC CIDR must come from the variable."
  }
}

run "public_subnets_do_not_auto_assign_public_ips" {
  command = plan

  assert {
    condition     = alltrue([for s in aws_subnet.public : s.map_public_ip_on_launch == false])
    error_message = "Public subnets should not auto-assign public IPs."
  }
}

run "single_nat_by_default_and_one_per_az_when_disabled" {
  command = plan

  assert {
    condition     = length(aws_nat_gateway.this) == 1
    error_message = "Default should create a single NAT gateway."
  }
}

run "nat_per_az_for_production" {
  command = plan

  variables {
    single_nat_gateway = false
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 2
    error_message = "Expected one NAT gateway per AZ."
  }
}

run "every_resource_carries_required_tags" {
  command = plan

  assert {
    condition     = alltrue([for t in [aws_vpc.this.tags, aws_internet_gateway.this.tags, aws_route_table.public.tags] : contains(keys(t), "Environment") && contains(keys(t), "Project")])
    error_message = "Environment and Project tags are required."
  }
}

run "rejects_invalid_cidr" {
  command = plan

  variables {
    vpc_cidr = "not-a-cidr"
  }

  expect_failures = [var.vpc_cidr]
}

run "rejects_single_az" {
  command = plan

  variables {
    availability_zones = ["ap-south-1a"]
  }

  expect_failures = [var.availability_zones]
}

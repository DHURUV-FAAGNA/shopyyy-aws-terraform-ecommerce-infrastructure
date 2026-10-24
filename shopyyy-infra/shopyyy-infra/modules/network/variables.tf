variable "name" {
  description = "Name prefix for all network resources."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC."
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "Availability zones to spread subnets across (at least 2)."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "Provide at least 2 availability zones."
  }
}

variable "subnet_newbits" {
  description = "Extra prefix bits added to the VPC CIDR for each subnet (4 turns a /16 into /20 subnets)."
  type        = number
  default     = 4
}

variable "single_nat_gateway" {
  description = "true = one shared NAT Gateway (cheaper, dev). false = one NAT per AZ (highly available, prod)."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to every resource (must include Environment and Project)."
  type        = map(string)
  default     = {}
}

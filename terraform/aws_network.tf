data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# Minimal VPC: public subnets only (no NAT gateway) to keep POC cost low.
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.name_prefix}-vpc"
  cidr = var.vpc_cidr

  azs            = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets = [for i in range(2) : cidrsubnet(var.vpc_cidr, 8, i + 1)]

  enable_nat_gateway      = false
  enable_dns_hostnames    = true
  enable_dns_support      = true
  map_public_ip_on_launch = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  tags = var.tags
}

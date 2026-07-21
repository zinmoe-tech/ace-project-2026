resource "aws_vpc" "profile-vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "profile-vpc"
  })
}

# Hosts the profile-service target — private only, reachable via the peered
# self-managed-worker VPC (see vpc-peering.tf).
resource "aws_subnet" "profile-private-subnet" {
  vpc_id                  = aws_vpc.profile-vpc.id
  cidr_block              = var.profile-private-sub
  availability_zone       = var.az
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "profile-private-sub-01"
  })
}




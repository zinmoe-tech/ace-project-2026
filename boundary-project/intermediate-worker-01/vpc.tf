resource "aws_vpc" "intermediate-worker-1-vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "intermediate-worker-1-vpc"
  })
}

resource "aws_internet_gateway" "intermediate-worker-1-igw" {
  vpc_id = aws_vpc.intermediate-worker-1-vpc.id

  tags = merge(var.tags, {
    Name = "intermediate-worker-1-igw"
  })
}

# Hosts the bastion host — the only host with a route to the internet gateway.
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.intermediate-worker-1-vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.az
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "boundary-intermediate-worker-1-public-sub-01"
  })
}

# Hosts the worker and profile_ec2 — no NAT/IGW, reachable only via VPC
# peering to the self-managed-worker VPC (see vpc-peering.tf).
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.intermediate-worker-1-vpc.id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = var.az
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "boundary-intermediate-worker-1-private-sub-01"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.intermediate-worker-1-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.intermediate-worker-1-igw.id
  }

  tags = merge(var.tags, {
    Name = "intermediate-worker-1-public-rt"
  })
}


# No default route: this subnet is peering-only (see vpc-peering.tf), not
# NAT'd — instances here can reach the self-managed-worker VPC directly but
# have no internet egress.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.intermediate-worker-1-vpc.id

  tags = merge(var.tags, {
    Name = "intermediate-worker-1-private-rt"
  })
}

resource "aws_route_table_association" "intermediate-worker-1-public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "intermediate-worker-1-private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

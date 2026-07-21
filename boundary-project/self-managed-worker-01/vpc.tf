resource "aws_vpc" "self-manged-worker-1-vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "boundary-self-managed-worker-vpc"
  })
}

resource "aws_internet_gateway" "self-managed-worker-igw" {
  vpc_id = aws_vpc.self-manged-worker-1-vpc.id

  tags = merge(var.tags, {
    Name = "boundary-igw"
  })
}

# Hosts the bastion host — the only host with a route to the internet gateway.
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.self-manged-worker-1-vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.az
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "boundary-self-manged-worker-public-sub-01"
  })
}

# Hosts the self-managed worker — outbound-only via NAT, no direct internet route.
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.self-manged-worker-1-vpc.id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = var.az
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "boundary-self-managed-private-sub-01"
  })
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "boundary-nat-eip"
  })
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = merge(var.tags, {
    Name = "boundary-nat-gw"
  })

  depends_on = [aws_internet_gateway.self-managed-worker-igw]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.self-manged-worker-1-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.self-managed-worker-igw.id
  }

  tags = merge(var.tags, {
    Name = "boundary-public-rt"
  })
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.self-manged-worker-1-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = merge(var.tags, {
    Name = "boundary-private-rt"
  })
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_vpc" "management-network-01-vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "management-network-01-vpc"
  })
}

resource "aws_subnet" "management-network-01-private" {
  vpc_id                  = aws_vpc.management-network-01-vpc.id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = var.az
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "management-network-01-private-sub-01"
  })
}

#purpose : this is for hosting the bastion, and giving the NAT gateway a
#route to the internet gateway.
resource "aws_subnet" "management-network-01-public" {
  vpc_id                  = aws_vpc.management-network-01-vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.az
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "management-network-01-public-sub-01"
  })
}

#purpose : this is for giving the public subnet (bastion, NAT gateway) a
#route to the internet.
resource "aws_internet_gateway" "management-network-01-igw" {
  vpc_id = aws_vpc.management-network-01-vpc.id

  tags = merge(var.tags, {
    Name = "management-network-01-igw"
  })
}

resource "aws_route_table" "management-network-01-public" {
  vpc_id = aws_vpc.management-network-01-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.management-network-01-igw.id
  }

  tags = merge(var.tags, {
    Name = "management-network-01-public-rt"
  })
}

resource "aws_route_table_association" "management-network-01-public" {
  subnet_id      = aws_subnet.management-network-01-public.id
  route_table_id = aws_route_table.management-network-01-public.id
}

#purpose : this is for letting intermediate-worker-01 reach the three HCP
#Boundary upstream addresses — a private-IP-only instance cannot use a
#plain internet gateway, so this is required even though the worker has no
#general internet access (see the narrow /32 routes below, not a
#0.0.0.0/0 default route).
resource "aws_eip" "management-network-01-nat" {
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "management-network-01-nat-eip"
  })
}

resource "aws_nat_gateway" "management-network-01-nat" {
  allocation_id = aws_eip.management-network-01-nat.id
  subnet_id     = aws_subnet.management-network-01-public.id

  tags = merge(var.tags, {
    Name = "management-network-01-nat-gw"
  })

  depends_on = [aws_internet_gateway.management-network-01-igw]
}

resource "aws_route_table" "management-network-01-private" {
  vpc_id = aws_vpc.management-network-01-vpc.id

  tags = merge(var.tags, {
    Name = "management-network-01-private-rt"
  })
}

resource "aws_route_table_association" "management-network-01-private" {
  subnet_id      = aws_subnet.management-network-01-private.id
  route_table_id = aws_route_table.management-network-01-private.id
}

#purpose : this is for routing intermediate-worker-01's traffic to each HCP
#Boundary upstream address through the NAT gateway — one explicit /32
#route per IP in hcp_boundary_upstream_ips, deliberately not a blanket
#0.0.0.0/0 route, so nothing else can reach the internet from here.
resource "aws_route" "private_to_hcp_boundary_upstream_1" {
  route_table_id         = aws_route_table.management-network-01-private.id
  destination_cidr_block = "${var.hcp_boundary_upstream_ips[0]}/32"
  nat_gateway_id         = aws_nat_gateway.management-network-01-nat.id
}

resource "aws_route" "private_to_hcp_boundary_upstream_2" {
  route_table_id         = aws_route_table.management-network-01-private.id
  destination_cidr_block = "${var.hcp_boundary_upstream_ips[1]}/32"
  nat_gateway_id         = aws_nat_gateway.management-network-01-nat.id
}

resource "aws_route" "private_to_hcp_boundary_upstream_3" {
  route_table_id         = aws_route_table.management-network-01-private.id
  destination_cidr_block = "${var.hcp_boundary_upstream_ips[2]}/32"
  nat_gateway_id         = aws_nat_gateway.management-network-01-nat.id
}

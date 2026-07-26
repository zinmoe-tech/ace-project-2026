#purpose : this is for creating the temporary VPC that Packer builds the
#boundary-worker AMI in. Nothing persistent lives here — meant to be
#destroyed (terraform destroy) right after the AMI build completes. The
#AMI/snapshots it produces live independently in AWS/HCP Packer and aren't
#affected by tearing this VPC down.
resource "aws_vpc" "packer-vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "packer-vpc"
  })
}

#purpose : this is for giving the build instance a route to the internet,
#so Packer's shell provisioner can download the Boundary binary.
resource "aws_internet_gateway" "packer-vpc-igw" {
  vpc_id = aws_vpc.packer-vpc.id

  tags = merge(var.tags, {
    Name = "packer-vpc-igw"
  })
}

#purpose : this is for hosting Packer's temporary build instance. Only a
#public subnet is needed — associate_public_ip_address = true in
#boundary-worker.pkr.hcl gives the build instance a public IP directly.
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.packer-vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.az
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "packer-vpc-public-sub-01"
  })
}

#purpose : this is for routing the public subnet's outbound traffic to the
#internet gateway.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.packer-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.packer-vpc-igw.id
  }

  tags = merge(var.tags, {
    Name = "packer-vpc-public-rt"
  })
}

#purpose : this is for attaching the public route table to the public
#subnet.
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

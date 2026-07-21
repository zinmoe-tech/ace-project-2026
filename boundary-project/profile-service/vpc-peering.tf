# The self-managed-worker VPC lives in a separate Terraform state (no shared
# backend between the two modules), so it's looked up here by its Name tag
# rather than passed in.
data "aws_vpc" "self_managed_worker" {
  filter {
    name   = "tag:Name"
    values = ["boundary-self-managed-worker-vpc"]
  }
}

resource "aws_vpc_peering_connection" "profile_to_worker" {
  vpc_id      = aws_vpc.profile-vpc.id
  peer_vpc_id = data.aws_vpc.self_managed_worker.id
  auto_accept = true

  tags = merge(var.tags, {
    Name = "profile-to-self-managed-worker-peering"
  })
}

resource "aws_route_table" "profile_private" {
  vpc_id = aws_vpc.profile-vpc.id

  route {
    cidr_block                = data.aws_vpc.self_managed_worker.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.profile_to_worker.id
  }

  tags = merge(var.tags, {
    Name = "profile-private-rt"
  })
}

resource "aws_route_table_association" "profile_private" {
  subnet_id      = aws_subnet.profile-private-subnet.id
  route_table_id = aws_route_table.profile_private.id
}

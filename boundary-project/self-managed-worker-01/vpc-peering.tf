# The peering connection is created (and auto-accepted, since both VPCs are in
# the same account/region) from the profile-service module's state — looked up
# here by its Name tag rather than passed in, since there's no shared backend
# between the two modules.
data "aws_vpc_peering_connection" "profile" {
  tags = {
    Name = "profile-to-self-managed-worker-peering"
  }
}

resource "aws_route" "private_to_profile" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = data.aws_vpc_peering_connection.profile.peer_cidr_block
  vpc_peering_connection_id = data.aws_vpc_peering_connection.profile.id
}

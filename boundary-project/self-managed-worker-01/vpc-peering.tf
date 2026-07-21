# The peering connection is created (and auto-accepted, since both VPCs are in
# the same account/region) from the profile-service module's state — looked up
# here by its Name tag rather than passed in, since there's no shared backend
# between the two modules.
#
# Bootstrap ordering: on a fresh deploy this connection doesn't exist yet
# (profile-service can't create it until THIS module's VPC already exists),
# so the lookup below is gated behind enable_profile_peering_route and
# defaults to off. Apply this module once first, then profile-service, then
# flip the variable to true and apply this module again to add the route.
data "aws_vpc_peering_connection" "profile" {
  count = var.enable_profile_peering_route ? 1 : 0

  tags = {
    Name = "profile-to-self-managed-worker-peering"
  }
}

resource "aws_route" "private_to_profile" {
  count = var.enable_profile_peering_route ? 1 : 0

  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = data.aws_vpc_peering_connection.profile[0].peer_cidr_block
  vpc_peering_connection_id = data.aws_vpc_peering_connection.profile[0].id
}

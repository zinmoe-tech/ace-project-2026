# Peers this VPC directly to the self-managed-worker VPC — the private
# subnet has no NAT gateway, so this peering connection is its only route
# anywhere. Created from this module's side (peer VPC looked up by tag,
# since there's no shared backend between the two modules); auto-accepted
# since both VPCs are in the same account/region.
data "aws_vpc" "self_managed_worker" {
  filter {
    name   = "tag:Name"
    values = ["boundary-self-managed-worker-vpc"]
  }
}

resource "aws_vpc_peering_connection" "intermediate_to_worker" {
  vpc_id      = aws_vpc.intermediate-worker-1-vpc.id
  peer_vpc_id = data.aws_vpc.self_managed_worker.id
  auto_accept = true

  tags = merge(var.tags, {
    Name = "intermediate-worker-to-self-managed-worker-peering"
  })
}

resource "aws_route" "private_to_self_managed_worker" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = data.aws_vpc.self_managed_worker.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.intermediate_to_worker.id
}

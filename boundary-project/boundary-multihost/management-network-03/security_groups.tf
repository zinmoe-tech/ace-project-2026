#purpose : this is for controlling intermediate-worker-03's network access.
#No ingress rules at all, and no allow-all egress — only the three explicit
#egress rules below (HCP Boundary's upstream addresses on 9202, from
#hcp_boundary_upstream_ips) are permitted out. This instance has no
#general internet access.
resource "aws_security_group" "intermediate_worker" {
  name        = "intermediate-worker-03-sg"
  description = "intermediate-worker-03-sg"
  vpc_id      = aws_vpc.management-network-03-vpc.id

  tags = var.tags
}

#purpose : this is for allowing intermediate-worker-03 to reach HCP
#Boundary's upstream on 9202.
resource "aws_vpc_security_group_egress_rule" "hcp_boundary_upstream_1" {
  security_group_id = aws_security_group.intermediate_worker.id
  description       = "HCP Boundary upstream"
  from_port         = 9202
  to_port           = 9202
  ip_protocol       = "tcp"
  cidr_ipv4         = "${var.hcp_boundary_upstream_ips[0]}/32"

  tags = var.tags
}

resource "aws_vpc_security_group_egress_rule" "hcp_boundary_upstream_2" {
  security_group_id = aws_security_group.intermediate_worker.id
  description       = "HCP Boundary upstream"
  from_port         = 9202
  to_port           = 9202
  ip_protocol       = "tcp"
  cidr_ipv4         = "${var.hcp_boundary_upstream_ips[1]}/32"

  tags = var.tags
}

resource "aws_vpc_security_group_egress_rule" "hcp_boundary_upstream_3" {
  security_group_id = aws_security_group.intermediate_worker.id
  description       = "HCP Boundary upstream"
  from_port         = 9202
  to_port           = 9202
  ip_protocol       = "tcp"
  cidr_ipv4         = "${var.hcp_boundary_upstream_ips[2]}/32"

  tags = var.tags
}

#purpose : this is for allowing SSH into intermediate-worker-03 from the
#bastion only, so worker-auth-token.tf can fetch auth_request_token. Not
#open to anything else — this is the only ingress rule on this instance.
resource "aws_vpc_security_group_ingress_rule" "ssh_from_bastion" {
  security_group_id            = aws_security_group.intermediate_worker.id
  description                  = "SSH from bastion"
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.bastion.id

  tags = var.tags
}

#purpose : this is for the bastion's own network access — SSH in from
#anywhere, unrestricted egress, same pattern as self-managed-worker-01's
#bastion security group.
resource "aws_security_group" "bastion" {
  name        = "intermediate-worker-03-bastion-sg"
  description = "intermediate-worker-03-bastion-sg"
  vpc_id      = aws_vpc.management-network-03-vpc.id

  tags = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "bastion_ssh" {
  security_group_id = aws_security_group.bastion.id
  description       = "SSH"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = var.tags
}

resource "aws_vpc_security_group_egress_rule" "bastion_all_egress" {
  security_group_id = aws_security_group.bastion.id
  description       = "All outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = var.tags
}

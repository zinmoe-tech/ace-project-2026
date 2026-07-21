resource "aws_security_group" "profile-sgp" {
  name        = "profile-sgp"
  description = "profile-sgp"
  vpc_id      = aws_vpc.profile-vpc.id

  tags = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "profile_ssh_ingress" {
  security_group_id = aws_security_group.profile-sgp.id
  description       = "SSH"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = var.tags
}

# Boundary worker's proxy listener, used by clients to reach sessions through this host.
resource "aws_vpc_security_group_egress_rule" "profile_boundary_worker_proxy_egress" {
  security_group_id = aws_security_group.profile-sgp.id
  description       = "Boundary worker proxy"
  from_port         = 9202
  to_port           = 9202
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = var.tags
}

resource "aws_vpc_security_group_egress_rule" "profile_ssh_egress" {
  security_group_id = aws_security_group.profile-sgp.id
  description       = "SSH"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = var.tags
}

resource "aws_security_group" "bastion" {
  name        = "bastion-host-sg"
  description = "bastion-host-sg"
  vpc_id      = aws_vpc.intermediate-worker-1-vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_security_group" "worker" {
  name        = "self-managed-worker-1-sg"
  description = "self-managed-worker-1-sg"
  vpc_id      = aws_vpc.intermediate-worker-1-vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ICMP"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # NOTE: the worker is tagged "ingress" in pki-worker.hcl and listens on 9202
  # for proxy traffic, but that port isn't open on the current security group.
  # Uncomment to let Boundary clients actually reach the proxy listener:
  # ingress {
  #   description = "Boundary worker proxy"
  #   from_port   = 9202
  #   to_port     = 9202
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

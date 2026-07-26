#purpose : this is for looking up the existing key pair to SSH into
#intermediate-worker-03 with (created out-of-band, .pem lives locally).
data "aws_key_pair" "worker" {
  key_name = var.worker_key_name
}

#purpose : this is for looking up the existing key pair to SSH into the
#bastion with (created out-of-band, .pem lives locally).
data "aws_key_pair" "bastion" {
  key_name = var.bastion_key_name
}

#purpose : this is for finding a stock Ubuntu AMI for the bastion — not
#the custom worker AMI, just a plain jump host.
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-resolute-26.04-amd64-server-*"]
  }
}

#purpose : this is for creating the bastion, used only to fetch
#intermediate-worker-03's auth_request_token over SSH (see
#worker-auth-token.tf).
resource "aws_instance" "bastion" {
  count = var.create_bastion_instance ? 1 : 0

  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.management-network-03-public.id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  key_name                    = data.aws_key_pair.bastion.key_name
  associate_public_ip_address = true

  tags = merge(var.tags, {
    Name = "intermediate-worker-03-bastion"
  })
}

#purpose : this is for resolving the boundary-worker AMI built by
#boundary-multihost/packer — count = 0 until create_worker_instance is
#flipped true, since nothing may have been published yet on a fresh setup.
data "hcp_packer_artifact" "worker" {
  count = var.create_worker_instance ? 1 : 0

  bucket_name  = var.hcp_packer_bucket_name
  channel_name = var.hcp_packer_channel
  platform     = "aws"
  region       = var.region
}

#purpose : this is for creating the intermediate-worker-03 EC2 instance in
#the private subnet, from the Packer-built AMI. No public IP — this
#network has no internet gateway at all, and the security group only
#allows the three HCP Boundary upstream egress rules.
resource "aws_instance" "intermediate_worker" {
  count = var.create_worker_instance ? 1 : 0

  ami                    = data.hcp_packer_artifact.worker[0].external_identifier
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.management-network-03-private.id
  vpc_security_group_ids = [aws_security_group.intermediate_worker.id]
  key_name               = data.aws_key_pair.worker.key_name

  tags = merge(var.tags, {
    Name = "intermediate-worker-03"
  })
}

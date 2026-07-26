# Both instances already have key pairs created out-of-band (the .pem files
# live locally) — looked up here rather than managed, so Terraform never
# regenerates/replaces a key you already have the private half of.
data "aws_key_pair" "bastion" {
  key_name = var.bastion_key_name
}

data "aws_key_pair" "worker" {
  key_name = var.worker_key_name
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-resolute-26.04-amd64-server-*"]
  }
}

# The worker-specific AMI published by packer/boundary-worker.pkr.hcl —
# built and channel-assigned separately, before this module is applied.
# Gated the same way as aws_instance.worker below: on a fresh deploy nothing
# has been published to the channel yet, so this must stay skipped until
# create_worker_instance is flipped to true (see variables.tf).
data "hcp_packer_artifact" "worker" {
  count = var.create_worker_instance ? 1 : 0

  bucket_name  = var.hcp_packer_bucket_name
  channel_name = var.hcp_packer_channel
  platform     = "aws"
  region       = var.region
}

resource "aws_instance" "bastion" {
  count = var.create_bastion_instance ? 1 : 0

  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  key_name                    = data.aws_key_pair.bastion.key_name
  associate_public_ip_address = true

  tags = merge(var.tags, {
    Name = "intermediate-bastion-host"
  })
}

# Reuses the AMI self-managed-worker-01's own packer/boundary-worker.pkr.hcl
# already built and published — same bucket_name/channel_name (see
# hcp_packer_bucket_name/hcp_packer_channel defaults in variables.tf), just
# consumed here to launch a second worker in a different VPC. Nothing to
# build in this module; count = 0 only until the AMI has been published at
# least once (by that other module) and this module's own public subnet
# exists for the bastion.
resource "aws_instance" "worker" {
  count = var.create_worker_instance ? 1 : 0

  ami                    = data.hcp_packer_artifact.worker[0].external_identifier
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.worker.id]
  key_name               = data.aws_key_pair.worker.key_name

  tags = merge(var.tags, {
    Name = "intermediate-worker-1"
  })
}

# Plain scratch/test box — stock Ubuntu, not the custom worker AMI. Reuses
# the worker security group and key pair since both already fit a
# private-subnet host; reachable via the bastion, or directly from the
# self-managed-worker VPC over the peering connection (see vpc-peering.tf).
resource "aws_instance" "profile_ec2" {
  count = var.create_profile_ec2_instance ? 1 : 0

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.worker.id]
  key_name               = data.aws_key_pair.worker.key_name

  tags = merge(var.tags, {
    Name = "profile-ec2"
  })
}

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
    Name = "bastion-host"
  })
}

# count = 0 on the first apply: this module's own public subnet has to
# exist before packer/build.sh can launch its temporary build instance
# into it, and the AMI that build produces has to exist before this
# instance can reference it. See create_worker_instance in variables.tf.
resource "aws_instance" "worker" {
  count = var.create_worker_instance ? 1 : 0

  ami                    = data.hcp_packer_artifact.worker[0].external_identifier
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.worker.id]
  key_name               = data.aws_key_pair.worker.key_name

  tags = merge(var.tags, {
    Name = "self-managed-worker-1"
  })
}

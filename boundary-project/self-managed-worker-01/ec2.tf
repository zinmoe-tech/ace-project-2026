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

resource "aws_instance" "bastion" {
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

resource "aws_instance" "worker" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.worker.id]
  key_name               = data.aws_key_pair.worker.key_name

  tags = merge(var.tags, {
    Name = "self-managed-worker-1"
  })
}

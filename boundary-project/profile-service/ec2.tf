# Key pair already created out-of-band (profile-key.pem lives locally) —
# looked up here rather than managed, so Terraform never regenerates/replaces
# a key you already have the private half of.
data "aws_key_pair" "profile" {
  key_name = "profile-key"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-resolute-26.04-amd64-server-*"]
  }
}

resource "aws_instance" "profile-instance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.profile-private-subnet.id
  vpc_security_group_ids = [aws_security_group.profile-sgp.id]
  key_name               = data.aws_key_pair.profile.key_name

  tags = merge(var.tags, {
    Name = "profile-service"
  })
}

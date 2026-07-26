# Key pair already created out-of-band (profile-key.pem lives locally) —
# looked up here rather than managed, so Terraform never regenerates/replaces
# a key you already have the private half of.
data "aws_key_pair" "profile" {
  key_name = "profile-key"
}

# Built by packer/profile-service.pkr.hcl — has the profile-service (renamed
# fake-service) binary and systemd unit pre-installed. Owned by this account
# ("self"), not "amazon", since it's the custom AMI, not stock Ubuntu.
data "aws_ami" "profile_service" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["profile-service-*"]
  }
}

resource "aws_instance" "profile-instance" {
  ami                    = data.aws_ami.profile_service.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.profile-private-subnet.id
  vpc_security_group_ids = [aws_security_group.profile-sgp.id]
  key_name               = data.aws_key_pair.profile.key_name

  tags = merge(var.tags, {
    Name = "profile-service"
  })
}

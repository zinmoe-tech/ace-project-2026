# Builds an Ubuntu AMI with the fake-service binary (renamed profile-service)
# and its systemd unit pre-installed. UPSTREAM_URIS/MESSAGE/NAME are baked in
# statically since there's currently only one profile-service instance.
#
# profile-vpc has no internet gateway or NAT gateway (see profile-vpc.tf) —
# only a peering route to the self-managed-worker VPC — so a build instance
# placed there can't reach GitHub to download the binary. This builds in the
# self-managed-worker VPC's public subnet instead (same subnet
# boundary-worker.pkr.hcl uses); the resulting AMI is portable and gets
# launched into profile-vpc afterward regardless of where it was built.

packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

variable "region" {
  type    = string
  default = "ap-southeast-1"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ssh_username" {
  type    = string
  default = "ubuntu"
}

variable "aws_profile" {
  type    = string
  default = "master-access"
}

source "amazon-ebs" "profile_service" {
  region        = var.region
  instance_type = var.instance_type
  ssh_username  = var.ssh_username
  profile       = var.aws_profile

  # Borrowed from the self-managed-worker VPC purely as a build staging
  # ground — it already has an internet gateway. Not related to where this
  # AMI actually runs.
  vpc_filter {
    filters = {
      "tag:Name" = "boundary-self-managed-worker-vpc"
    }
  }

  subnet_filter {
    filters = {
      "tag:Name" = "boundary-self-manged-worker-public-sub-01"
    }
    random = false
  }

  associate_public_ip_address = true

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd-gp3/ubuntu-resolute-26.04-amd64-server-*"
      virtualization-type = "hvm"
      root-device-type    = "ebs"
    }
    owners      = ["amazon"]
    most_recent = true
  }

  ami_name = "profile-service-{{timestamp}}"

  tags = {
    Name      = "profile-service"
    ManagedBy = "packer"
  }
}

build {
  name    = "profile-service"
  sources = ["source.amazon-ebs.profile_service"]

  provisioner "file" {
    source      = "files/profile.service"
    destination = "/tmp/profile.service"
  }

  provisioner "shell" {
    script = "scripts/install-profile-service.sh"
  }
}

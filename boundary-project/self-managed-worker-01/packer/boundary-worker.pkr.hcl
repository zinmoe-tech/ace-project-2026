# Builds an Ubuntu AMI with the Boundary self-managed PKI worker binary and
# systemd unit pre-installed, and publishes it to the HCP Packer registry.
#
# Registration is deliberately NOT baked in here: public_addr and the
# auth_request_token flow are per-instance, so pki-worker.hcl is written from
# a template at first boot (see files/render-boundary-config.sh) instead of
# being fixed at build time. That's what keeps this AMI reusable across
# instances rather than tied to one IP.
#
# Requires HCP_CLIENT_ID / HCP_CLIENT_SECRET (or HCP_PROJECT_ID) in the
# environment for the hcp_packer_registry block to publish successfully.

packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

# Publishes the resulting AMI to the HCP Packer registry once the build
# completes, so it can be tracked by version/channel instead of AMI ID.
# Top-level (not nested in `build`) — nesting it there is deprecated as of
# Packer 1.12.1+.
hcp_packer_registry {
  bucket_name = "boundary-self-managed-worker" # groups every build of this template together in HCP Packer

  description = "Ubuntu AMI with the Boundary self-managed PKI worker pre-installed; renders its config and registers with HCP Boundary on first boot." # shown in the HCP Packer UI

  # Labels on the bucket itself (apply to every version/build published under it).
  bucket_labels = {
    "project" = "boundary-project"
  }

  # Labels on this specific build/version (can vary build to build, e.g. by OS or component).
  build_labels = {
    "os"        = "ubuntu"
    "component" = "boundary-worker"
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

# Matches aws_profile in both Terraform modules — named explicitly so this
# doesn't silently depend on whatever AWS credentials happen to be default.
variable "aws_profile" {
  type    = string
  default = "master-access"
}

# These three are NOT read by the hcp_packer_registry block above — HCP auth
# happens via the environment (see build.sh) before Packer ever evaluates
# variables. They're declared here only so hcp.auto.pkrvars.hcl is valid
# HCL that `packer build`/`packer validate` won't reject as an unknown
# argument.
variable "hcp_project_id" {
  type = string
}

variable "hcp_client_id" {
  type = string
}

variable "hcp_client_secret" {
  type      = string
  sensitive = true
}

source "amazon-ebs" "boundary_worker" {
  region        = var.region
  instance_type = var.instance_type
  ssh_username  = var.ssh_username
  profile       = var.aws_profile

  # This account has no default VPC, so the temporary build instance needs
  # an explicit landing spot. Found by tag rather than hardcoded ID since
  # the VPC/subnet are created by ../vpc.tf (a separate Terraform apply,
  # not this Packer run) — same tag-lookup pattern used for VPC peering
  # elsewhere in this project. Needs create_bastion_instance/
  # create_worker_instance = false but the network resources themselves
  # already applied (see terraform.tfvars / SETUP.md phase order).
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

  ami_name = "boundary-self-managed-worker-{{timestamp}}"

  # Default AMI root volume (~8GB) isn't enough headroom for apt-get's
  # package caches plus the downloaded+unpacked Boundary Enterprise zip in
  # scripts/install-boundary.sh, which failed extraction with unzip exit
  # code 50 (disk full).
  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = 16
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name      = "boundary-self-managed-worker"
    ManagedBy = "packer"
  }
}

build {
  name    = "boundary-worker"
  sources = ["source.amazon-ebs.boundary_worker"]

  provisioner "file" {
    source      = "files/pki-worker.hcl.tmpl"
    destination = "/tmp/pki-worker.hcl.tmpl"
  }

  provisioner "file" {
    source      = "files/render-boundary-config.sh"
    destination = "/tmp/render-boundary-config.sh"
  }

  provisioner "file" {
    source      = "files/boundary-worker.service"
    destination = "/tmp/boundary-worker.service"
  }

  # Runs after the three file provisioners above, on the same temporary build
  # instance. Installs the boundary binary, creates the boundary user, moves
  # the three staged /tmp files into their real locations, and enables (but
  # does not start) the systemd service.
  provisioner "shell" {
    script = "scripts/install-boundary.sh" # path to the script, relative to this .pkr.hcl file
  }
}

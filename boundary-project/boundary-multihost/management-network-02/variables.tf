variable "region" {
  description = "AWS region hosting management-network-02."
  type        = string
  default     = "ap-southeast-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to authenticate with."
  type        = string
  default     = "master-access"
}

variable "vpc_cidr" {
  description = "CIDR block for the management-network-02 VPC."
  type        = string
  default     = "10.2.0.0/16"
}

variable "az" {
  description = "Availability zone for the private subnet."
  type        = string
  default     = "ap-southeast-1a"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet."
  type        = string
  default     = "10.2.15.0/24"
}

#purpose : this is for the bastion/NAT gateway subnet.
variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet."
  type        = string
  default     = "10.2.100.0/24"
}

variable "tags" {
  type    = map(string)
  default = {}
}

#purpose : this is for sizing the intermediate-worker-02 EC2 instance.
variable "instance_type" {
  type    = string
  default = "t3.micro"
}

#purpose : this is for looking up the existing EC2 key pair to launch
#intermediate-worker-02 with (created out-of-band, .pem lives locally).
variable "worker_key_name" {
  type    = string
  default = "self-managed-worker-01"
}

#purpose : this is for gating creation of the intermediate-worker-02
#instance until the Packer AMI has actually been published.
variable "create_worker_instance" {
  type    = bool
  default = false
}

#purpose : this is for gating creation of the bastion instance, used only
#to fetch intermediate-worker-02's auth_request_token over SSH.
variable "create_bastion_instance" {
  type    = bool
  default = false
}

#purpose : this is for looking up the existing EC2 key pair to launch the
#bastion with (created out-of-band, .pem lives locally).
variable "bastion_key_name" {
  type    = string
  default = "jump-host-key-pair"
}

#purpose : this is for authenticating the hcp provider (same service
#principal used by boundary-multihost/packer/hcp.auto.pkrvars.hcl).
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

#purpose : this is for pulling the right AMI out of HCP Packer — must match
#bucket_name/channel_name in boundary-multihost/packer/boundary-worker.pkr.hcl.
variable "hcp_packer_bucket_name" {
  type    = string
  default = "boundary-self-managed-worker"
}

variable "hcp_packer_channel" {
  type    = string
  default = "latest"
}

#purpose : this is for listing the HCP Boundary upstream addresses
#intermediate-worker-02 is allowed to reach on 9202 — the only egress
#permitted from this instance.
variable "hcp_boundary_upstream_ips" {
  type    = list(string)
  default = []
}

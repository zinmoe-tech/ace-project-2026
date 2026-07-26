variable "region" {
  description = "AWS region hosting the boundary self-managed worker setup."
  type        = string
  default     = "ap-southeast-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to authenticate with."
  type        = string
  default     = "master-access"
}

variable "vpc_cidr" {
  description = "CIDR block for the boundary VPC."
  type        = string
  default     = "10.1.0.0/16"
}

variable "az" {
  description = "Availability zone for the public/private subnet pair."
  type        = string
  default     = "ap-southeast-1a"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.1.100.0/24"
}

variable "private_subnet_cidr" {
  type    = string
  default = "10.1.1.0/24"
}

variable "instance_type" {
  description = "Instance type for both the bastion and the boundary worker."
  type        = string
  default     = "t3.micro"
}

variable "bastion_key_name" {
  description = "Existing EC2 key pair used to SSH into the bastion host."
  type        = string
  default     = "jump-host-key-pair"
}

variable "worker_key_name" {
  description = "Existing EC2 key pair used to SSH into the boundary worker."
  type        = string
  default     = "self-managed-worker-01"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "create_bastion_instance" {
  description = "Whether to create the bastion EC2 instance."
  type        = bool
  default     = false
}

variable "create_worker_instance" {
  description = "Whether to create the worker EC2 instance. Must be false on the first apply (network only) — the Packer build needs this module's public subnet to exist before it can run, and the worker instance needs the Packer build's AMI to exist before IT can be created. Set true and re-apply only after packer/build.sh has published an image to the channel named in hcp_packer_channel."
  type        = bool
  default     = false
}

variable "create_profile_ec2_instance" {
  description = "Whether to create the plain-Ubuntu profile_ec2 scratch instance."
  type        = bool
  default     = false
}

variable "hcp_project_id" {
  description = "HCP project ID that owns the Packer registry bucket the worker AMI was published to."
  type        = string
}

variable "hcp_client_id" {
  description = "HCP service principal client ID (same one used by packer/build.sh)."
  type        = string
}

variable "hcp_client_secret" {
  description = "HCP service principal client secret."
  type        = string
  sensitive   = true
}

variable "hcp_packer_bucket_name" {
  description = "HCP Packer registry bucket name. Must match bucket_name in packer/boundary-worker.pkr.hcl."
  type        = string
  default     = "boundary-self-managed-worker"
}

variable "hcp_packer_channel" {
  description = "HCP Packer channel to pull the worker AMI from. Must exist and be assigned to a build before this module's first apply against it."
  type        = string
  default     = "production"
}

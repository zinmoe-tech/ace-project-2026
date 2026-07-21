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

variable "region" {
  description = "AWS region hosting the temporary Packer build VPC."
  type        = string
  default     = "ap-southeast-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to authenticate with."
  type        = string
  default     = "master-access"
}

variable "vpc_cidr" {
  description = "CIDR block for the packer-vpc. Deliberately far from every other VPC's range in this account (10.1-10.3, 192.168) so it can never collide."
  type        = string
  default     = "10.100.0.0/16"
}

variable "az" {
  description = "Availability zone for the public subnet."
  type        = string
  default     = "ap-southeast-1a"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet Packer builds its temporary instance in."
  type        = string
  default     = "10.100.100.0/24"
}

variable "tags" {
  type    = map(string)
  default = {}
}

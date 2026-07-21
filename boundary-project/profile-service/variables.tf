variable "region" {
  description = "AWS region hosting the profile-service."
  type        = string
  default     = "ap-southeast-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to authenticate with."
  type        = string
  default     = "master-access"
}

# Must not overlap the self-managed-worker VPC's 10.1.0.0/16 — the two are peered.
variable "vpc_cidr" {
  description = "CIDR block for the profile VPC."
  type        = string
  default     = "192.168.0.0/16"
}

variable "az" {
  description = "Availability zone for the private subnet."
  type        = string
  default     = "ap-southeast-1a"
}

variable "profile-private-sub" {
  description = "CIDR block for the profile private subnet."
  type        = string
  default     = "192.168.10.0/24"
}

variable "instance_type" {
  description = "Instance type for the profile-service host."
  type        = string
  default     = "t3.micro"
}

variable "tags" {
  type    = map(string)
  default = {}
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.8"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  # The 3 AZs we spread across (e.g. ap-southeast-1a/1b/1c). See locals in this file.
  azs = local.azs

  # Build one subnet per AZ by slicing the VPC CIDR (10.0.0.0/16) into smaller blocks.
  #
  # `for k, v in local.azs` iterates the AZ list:
  #   k = index (0, 1, 2)   <- the only part we use
  #   v = AZ name           <- ignored here
  #
  # `cidrsubnet(prefix, newbits, netnum)`:
  #   prefix  = 10.0.0.0/16  (the whole VPC)
  #   newbits = 4            -> extend the mask /16 -> /20 (each /20 = 4096 IPs,
  #                             and 4 bits = 16 possible blocks, numbered 0..15)
  #   netnum  = which /20 block to carve out
  #
  # Private uses blocks 0,1,2 -> 10.0.0.0/20, 10.0.16.0/20, 10.0.32.0/20
  private_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 4, k)]
  #
  # Public uses blocks 8,9,10 (the `+ 8` offset) -> 10.0.128.0/20, 10.0.144.0/20,
  # 10.0.160.0/20. The offset guarantees public ranges never overlap the private
  # ones above, while still giving one subnet per AZ.
  public_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 4, k + 8)]

  # Single NAT gateway keeps cost down for non-prod. Set to false + one-per-AZ
  # for production HA.
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  # Tags required by EKS so the AWS cloud controller can discover subnets for
  # load balancers. Public subnets host internet-facing NLBs (the Istio global
  # gateway); private subnets host the worker nodes.
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = var.tags
}

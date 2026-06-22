module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.24"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  # Public endpoint so you can reach the API from your laptop. Lock this down
  # with cluster_endpoint_public_access_cidrs for production.
  cluster_endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Core add-ons. AWS VPC CNI is the chosen pod network (not Cilium).
  # (No aws-ebs-csi-driver: Istio needs no persistent storage, and that addon
  # would require its own IRSA IAM role to function. Add it back — with a role —
  # only if other workloads need EBS volumes.)
  cluster_addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni    = {}
  }

  eks_managed_node_groups = {
    default = {
      instance_types = var.node_instance_types

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      # Workers live in private subnets; egress via the NAT gateway.
      subnet_ids = module.vpc.private_subnets
    }
  }

  # Give the identity running terraform admin access to the cluster.
  enable_cluster_creator_admin_permissions = true

  tags = var.tags
}

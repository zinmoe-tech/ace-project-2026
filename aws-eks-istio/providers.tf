provider "aws" {
  region  = var.region
  profile = var.aws_profile
}

# Auth for the kubernetes/helm providers is derived from the EKS cluster that
# this same configuration creates. We use the `aws eks get-token` exec plugin so
# no long-lived (and no in-state) token is needed. The same aws_profile is passed
# through (when set) so the token is fetched with the same creds as the provider.
locals {
  eks_token_args = concat(
    ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.region],
    var.aws_profile == null ? [] : ["--profile", var.aws_profile],
  )
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = local.eks_token_args
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = local.eks_token_args
    }
  }
}

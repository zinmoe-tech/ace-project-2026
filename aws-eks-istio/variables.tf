variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "ap-southeast-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
  default     = "idp-cluster"
}

variable "kubernetes_version" {
  description = "EKS Kubernetes control plane version (minor only, e.g. \"1.33\" — NOT a patch like 1.33.x; AWS manages the patch). Unrelated to istio_version. Verify it's in EKS standard support before applying: aws eks describe-cluster-versions"
  type        = string
  default     = "1.33"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "node_instance_types" {
  description = "Instance types for the EKS managed node group."
  type        = list(string)
  default     = ["t3.large"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 3
}

variable "node_min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 5
}

variable "istio_version" {
  description = "Istio chart/control-plane version. Matches the tag in your local minimal-profile.yaml."
  type        = string
  default     = "1.29.2"
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default = {
    Project   = "ace-project-2026"
    ManagedBy = "terraform"
  }
}

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
  }

  # Recommended: store state remotely. Uncomment and set your bucket/table.
  # backend "s3" {
  #   bucket         = "my-tf-state-bucket"
  #   key            = "ace-project-2026/aws-eks-istio/terraform.tfstate"
  #   region         = "ap-southeast-1"
  #   dynamodb_table = "tf-locks"
  #   encrypt        = true
  # }
}

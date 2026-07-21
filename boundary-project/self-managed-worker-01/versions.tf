terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }

  # Recommended: store state remotely. Uncomment and set your bucket/table.
  # backend "s3" {
  #   bucket         = "my-tf-state-bucket"
  #   key            = "ace-project-2026/boundary/terraform.tfstate"
  #   region         = "ap-southeast-1"
  #   dynamodb_table = "tf-locks"
  #   encrypt        = true
  # }
}

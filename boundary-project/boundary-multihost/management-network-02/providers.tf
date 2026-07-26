provider "aws" {
  region  = var.region
  profile = var.aws_profile
}

#purpose : this is for authenticating to HCP Packer so data.hcp_packer_artifact
#can resolve the boundary-worker AMI.
provider "hcp" {
  client_id     = var.hcp_client_id
  client_secret = var.hcp_client_secret
  project_id    = var.hcp_project_id
}

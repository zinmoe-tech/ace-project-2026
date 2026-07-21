provider "aws" {
  region  = var.region
  profile = var.aws_profile
}

# Unlike Packer's hcp_packer_registry block, this provider's client_id /
# client_secret / project_id ARE real configurable arguments — no env-var
# workaround needed, they can come straight from terraform.tfvars.
provider "hcp" {
  client_id     = var.hcp_client_id
  client_secret = var.hcp_client_secret
  project_id    = var.hcp_project_id
}

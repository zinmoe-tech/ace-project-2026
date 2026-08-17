# -----------------------------------------------------------------------------
# Provider Configuration
# -----------------------------------------------------------------------------
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    boundary = {
      source  = "hashicorp/boundary"
      version = "~> 1.1"
    }
  }
}

provider "azurerm" {
  features {}
}

# Credentials come from TF_VAR_boundary_password (see variables.tf) — never
# hardcoded here. auth_method_id is the org's initial password auth method.
provider "boundary" {
  addr                   = "https://0df56b42-1dcf-4236-8b0d-abaaf4c53353.boundary.hashicorp.cloud"
  auth_method_id         = "ampw_sVTvvqApr1"
  auth_method_login_name = "admin"
  auth_method_password   = var.boundary_password
}
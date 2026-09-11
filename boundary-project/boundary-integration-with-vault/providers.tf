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
    vault = {
      source  = "hashicorp/vault"
      version = "5.10.1"
    }
  }
}

provider "azurerm" {
  features {}
}

# Credentials come from TF_VAR_boundary_password (see variables.tf) — never
# hardcoded here. auth_method_id is the org's initial password auth method.
provider "boundary" {
  addr                   = var.boundary_addr
  auth_method_id         = var.boundary_auth_method_id
  auth_method_login_name = var.boundary_login_name
  auth_method_password   = var.boundary_password
}

provider "vault" {
  address = var.vault_addr
  token   = var.vault_token
}

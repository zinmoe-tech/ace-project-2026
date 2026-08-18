# Set via TF_VAR_boundary_password — never put the real value in this file
# or in a .tfvars file that gets committed.
variable "boundary_password" {
  type      = string
  sensitive = true
}

# The project scope (p_...) that linux-target-vm-01's Boundary resources
# get created in. Find it with:
#   boundary scopes list -recursive -format json | jq '.items[] | select(.type=="project")'
variable "boundary_project_scope_id" {
  type = string
}

# Azure AD service principals for the Azure dynamic host-catalog plugin
# (ARM API discovery) — unrelated to the SSH key in ssh_key.tf, which is
# only for logging into the VMs. Two separate principals, one per VM,
# because linux-target-03's catalog disables credential rotation while
# linux-target-04's enables it: sharing one identity would mean enabling
# rotation on vm-04's catalog silently invalidates vm-03's stored secret.
variable "azure_tenant_id" {
  type = string
}

variable "azure_subscription_id" {
  type    = string
  default = "8d155826-e421-4063-91f2-23ddd65102f1"
}

variable "azure_sp_client_id" {
  type = string
}

variable "azure_sp_client_secret" {
  type      = string
  sensitive = true
}

variable "azure_sp_linux_target_04_client_id" {
  type = string
}

variable "azure_sp_linux_target_04_client_secret" {
  type      = string
  sensitive = true
}

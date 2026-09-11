# Set via TF_VAR_boundary_password. Never put the real value in this file
# or in a committed .tfvars file.
variable "boundary_password" {
  type      = string
  sensitive = true
}

variable "boundary_addr" {
  type        = string
  description = "Boundary cluster address."
}

variable "boundary_auth_method_id" {
  type        = string
  description = "Boundary password auth method ID used by the provider."
}

variable "boundary_login_name" {
  type        = string
  description = "Boundary username used by the provider."
}

variable "vault_addr" {
  type        = string
  description = "HCP Vault public cluster address."
}

variable "vault_token" {
  type        = string
  description = "Vault token used by the Terraform Vault provider."
  sensitive   = true
}

variable "boundary_controller_upstream_ips" {
  type        = list(string)
  description = "Boundary controller or upstream worker public IPs allowed for outbound TCP 9202."
}

variable "azure_ssh_public_key_name" {
  type        = string
  description = "Name of the Azure SSH public key used for VM admin access."
}

variable "azure_ssh_public_key_resource_group_name" {
  type        = string
  description = "Resource group containing the Azure SSH public key."
}

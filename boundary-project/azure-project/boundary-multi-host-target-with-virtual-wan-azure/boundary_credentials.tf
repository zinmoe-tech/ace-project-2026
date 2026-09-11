# DEPRECATED — no longer injected into any target (see
# boundary_linux_target_static_registration.tf /
# boundary_linux_target_dynamic_registration.tf, which now use
# boundary_credential_library_vault_ssh_certificate.linux_target_cert
# below). Left defined, not deleted, so this long-lived key stays available
# as a manual break-glass credential in Boundary if the Vault path ever
# goes down; delete once Vault has been confirmed working in practice.
resource "boundary_credential_store_static" "linux_targets" {
  name        = "linux-targets-cred-store"
  description = "Shared credential store for all linux target VMs (break-glass, unused)"
  scope_id    = var.boundary_project_scope_id
}

resource "boundary_credential_ssh_private_key" "linux_target_key" {
  name                = "linux-target-ssh-key"
  credential_store_id = boundary_credential_store_static.linux_targets.id
  username            = "azureuser"
  private_key         = file("${path.module}/key/linux_key")
}

# Vault SSH CA issues a short-lived certificate per session instead of
# handing out this static key. Setup for the Vault side (SSH secrets
# engine, CA, boundary-client role, policy/token) is documented in
# ../../boundary-integration-with-vault/ssh-certificate-injection.md.
resource "boundary_credential_store_vault" "linux_targets" {
  name        = "linux-targets-vault-cred-store"
  description = "Vault SSH certificate store for linux target VMs"
  address     = var.vault_addr
  token       = var.boundary_vault_token
  scope_id    = var.boundary_project_scope_id
}

resource "boundary_credential_library_vault_ssh_certificate" "linux_target_cert" {
  name                = "linux-target-ssh-cert"
  description         = "Short-lived SSH certificates for azureuser, issued by Vault"
  credential_store_id = boundary_credential_store_vault.linux_targets.id
  path                = "ssh-client-signer/sign/boundary-client"
  username            = "azureuser"
  key_type            = "ecdsa"
  key_bits            = 521
  ttl                 = "1h"

  extensions = {
    permit-pty = ""
  }
}

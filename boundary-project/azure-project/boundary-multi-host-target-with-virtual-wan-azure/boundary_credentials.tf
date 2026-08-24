# Shared credential store + SSH key credential for all linux targets. One
# store, one credential per distinct key — if a future target VM uses a
# different key, add another boundary_credential_ssh_private_key here (not
# a new store), and wire it into only the target(s) that need it via that
# target's injected_application_credential_source_ids.

resource "boundary_credential_store_static" "linux_targets" {
  name        = "linux-targets-cred-store"
  description = "Shared credential store for all linux target VMs"
  scope_id    = var.boundary_project_scope_id
}

# key/linux_key — used by linux-target-vm-01 and linux-target-vm-02 (both
# share this key today; see vm_linux_target-01.tf / vm_linux_target-02.tf).
resource "boundary_credential_ssh_private_key" "linux_target_key" {
  name                = "linux-target-ssh-key"
  credential_store_id = boundary_credential_store_static.linux_targets.id
  username            = "azureuser"
  private_key         = file("${path.module}/key/linux_key")
}

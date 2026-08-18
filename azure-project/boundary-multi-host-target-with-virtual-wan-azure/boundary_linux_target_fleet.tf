# Catalog: one shared discovery credential for every VM in the fleet, not
# tied to any single VM (unlike linux-target-03/04, which each get their
# own catalog). Backed by var.azure_sp_client_id/secret — the same
# credential linux-target-03's own catalog uses (boundary_linux_target_registration.tf),
# reused here only because rotation happens to be disabled on that
# particular service principal, so its secret is a stable value a second
# catalog can safely read. A rotation-enabled SP (like linux-target-04's)
# can't be reused this way: Boundary would change that secret on its own
# schedule and race whichever catalog reads it second.
resource "boundary_host_catalog_plugin" "linux_targets_fleet_dynamic" {
  name        = "linux-targets-fleet-azure-dynamic"
  description = "Shared Azure dynamic discovery catalog for the linux-target fleet (auto-registers new VMs tagged boundary_fleet=linux-target)"
  scope_id    = var.boundary_project_scope_id
  plugin_name = "azure"

  attributes_json = jsonencode({
    disable_credential_rotation = true
    tenant_id                   = var.azure_tenant_id
    subscription_id             = var.azure_subscription_id
    client_id                   = var.azure_sp_client_id
  })

  secrets_json = jsonencode({
    secret_value = var.azure_sp_client_secret
  })
}

# Host set: broad tag filter, not a per-VM address. Any VM tagged
# boundary_fleet = "linux-target" is auto-discovered here — a new VM
# (linux-target-05, -06, ...) needs only that tag set on its own
# azurerm_linux_virtual_machine resource, zero new Boundary Terraform.
resource "boundary_host_set_plugin" "linux_targets_fleet_dynamic" {
  name            = "linux-targets-fleet-set-dynamic"
  host_catalog_id = boundary_host_catalog_plugin.linux_targets_fleet_dynamic.id

  attributes_json = jsonencode({
    filter = "tagName eq 'boundary_fleet' and tagValue eq 'linux-target'"
  })
}

# Target: one SSH target for the whole host set above. Existing
# linux-target-01..04 are untagged/untouched, so they stay reachable only
# through their own targets in boundary_linux_target_registration.tf — this
# one is additive, for VMs going forward.
resource "boundary_target" "linux_target_fleet_ssh" {
  name                     = "linux-target-fleet-ssh-tf"
  description              = "Reaches every VM tagged boundary_fleet=linux-target, present or future"
  scope_id                 = var.boundary_project_scope_id
  type                     = "ssh"
  default_port             = 22
  session_connection_limit = -1
  ingress_worker_filter    = "\"ingress-worker\" in \"/tags/type\""
  egress_worker_filter     = "\"egress-worker\" in \"/tags/type\""

  host_source_ids = [
    boundary_host_set_plugin.linux_targets_fleet_dynamic.id,
  ]

  injected_application_credential_source_ids = [
    boundary_credential_ssh_private_key.linux_target_key.id,
  ]
}

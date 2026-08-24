resource "boundary_host_catalog_static" "static_host_catalog" {
  name        = "static_host_catalog"
  description = "for target-01 and target-02"
  scope_id    = var.boundary_project_scope_id
}

# ---------------------------------------------------------------------------
# linux-target-01
# ---------------------------------------------------------------------------

resource "boundary_host_static" "linux_target_01" {
  name            = "${azurerm_linux_virtual_machine.linux_target_01.name}-zm"
  host_catalog_id = boundary_host_catalog_static.static_host_catalog.id
  address         = azurerm_network_interface.linux_target_01.private_ip_address
}

resource "boundary_host_set_static" "linux_targets_01" {
  name            = "linux-targets-01-host-set"
  host_catalog_id = boundary_host_catalog_static.static_host_catalog.id
  host_ids        = [boundary_host_static.linux_target_01.id]
}

resource "boundary_target" "linux_target_01_ssh" {
  name                     = "${azurerm_linux_virtual_machine.linux_target_01.name}-ssh-tf"
  scope_id                 = var.boundary_project_scope_id
  type                     = "ssh"
  default_port             = 22
  session_connection_limit = -1
  ingress_worker_filter    = "\"ingress-worker\" in \"/tags/type\""
  egress_worker_filter     = "\"egress-worker\" in \"/tags/type\""

  host_source_ids = [
    boundary_host_set_static.linux_targets_01.id,
  ]

  injected_application_credential_source_ids = [
    boundary_credential_ssh_private_key.linux_target_key.id,
  ]
}

# ---------------------------------------------------------------------------
# linux-target-02
# ---------------------------------------------------------------------------

resource "boundary_host_static" "linux_target_02" {
  name            = "${azurerm_linux_virtual_machine.linux_target_02.name}-zm"
  host_catalog_id = boundary_host_catalog_static.static_host_catalog.id
  address         = azurerm_network_interface.linux_target_02.private_ip_address
}

resource "boundary_host_set_static" "linux_targets_02" {
  name            = "linux-targets-02-host-set"
  host_catalog_id = boundary_host_catalog_static.static_host_catalog.id
  host_ids        = [boundary_host_static.linux_target_02.id]
}

resource "boundary_target" "linux_target_02_ssh" {
  name                     = "${azurerm_linux_virtual_machine.linux_target_02.name}-ssh-tf"
  scope_id                 = var.boundary_project_scope_id
  type                     = "ssh"
  default_port             = 22
  session_connection_limit = -1
  ingress_worker_filter    = "\"ingress-worker\" in \"/tags/type\""
  egress_worker_filter     = "\"egress-worker\" in \"/tags/type\""

  host_source_ids = [
    boundary_host_set_static.linux_targets_02.id,
  ]

  injected_application_credential_source_ids = [
    boundary_credential_ssh_private_key.linux_target_key.id,
  ]
}

# ---------------------------------------------------------------------------
# linux-target-03 — Azure dynamic discovery, credential rotation DISABLED.
# Boundary will not touch the service principal's secret in Azure AD; the
# value in var.azure_sp_client_secret stays authoritative until rotated
# manually. Same variable the fleet catalog reuses — see
# boundary_linux_target_fleet.tf.
# ---------------------------------------------------------------------------
# resource "boundary_host_catalog_plugin" "linux_targets_03_dynamic" {
#   name        = "linux-targets-03-azure-dynamic"
#   description = "linux-target-03 — Azure dynamic discovery (credential rotation disabled)"
#   scope_id    = var.boundary_project_scope_id
#   plugin_name = "azure"

#   attributes_json = jsonencode({
#     disable_credential_rotation = true
#     tenant_id                   = var.azure_tenant_id
#     subscription_id             = var.azure_subscription_id
#     client_id                   = var.azure_sp_client_id
#   })

#   secrets_json = jsonencode({
#     secret_value = var.azure_sp_client_secret
#   })
# }

# ###To call the Azure Resource Manager API and discover the VM's IP by tag
# resource "boundary_host_set_plugin" "linux_targets_03_dynamic" {
#   name            = "linux-targets-03-set-dynamic"
#   host_catalog_id = boundary_host_catalog_plugin.linux_targets_03_dynamic.id

#   attributes_json = jsonencode({
#     filter = "tagName eq 'boundary_dynamic_target' and tagValue eq 'linux-target-03'"
#   })
# }

# resource "boundary_target" "linux_target_03_ssh" {
#   name                     = "${azurerm_linux_virtual_machine.linux_target_03.name}-ssh-tf"
#   scope_id                 = var.boundary_project_scope_id
#   type                     = "ssh"
#   default_port             = 22
#   session_connection_limit = -1
#   ingress_worker_filter    = "\"ingress-worker\" in \"/tags/type\""
#   egress_worker_filter     = "\"egress-worker\" in \"/tags/type\""

#   host_source_ids = [
#     boundary_host_set_plugin.linux_targets_03_dynamic.id,
#   ]

#   injected_application_credential_source_ids = [
#     boundary_credential_ssh_private_key.linux_target_key.id,
#   ]
# }


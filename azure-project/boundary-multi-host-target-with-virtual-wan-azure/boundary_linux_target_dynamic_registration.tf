resource "boundary_host_catalog_plugin" "dynamic-host-catalog" {
  name        = "dynamic-host-catalog"
  description = "For vm-03 and vm-04"
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

# Two separate host-sets, one per VM, each filtered on the tag that VM
# actually carries (boundary_dynamic_target — see vm_linux_target-03.tf /
# -04.tf), not a shared "boundary_fleet" tag neither VM has. A single
# broad host-set here would mean both targets reach both VMs.
resource "boundary_host_set_plugin" "linux_target_03_host_set" {
  name            = "linux-target-03-host-set"
  host_catalog_id = boundary_host_catalog_plugin.dynamic-host-catalog.id

  attributes_json = jsonencode({
    filter = "tagName eq 'boundary_dynamic_target' and tagValue eq 'linux-target-03'"
  })
}

resource "boundary_host_set_plugin" "linux_target_04_host_set" {
  name            = "linux-target-04-host-set"
  host_catalog_id = boundary_host_catalog_plugin.dynamic-host-catalog.id

  attributes_json = jsonencode({
    filter = "tagName eq 'boundary_dynamic_target' and tagValue eq 'linux-target-04'"
  })
}

####################################

resource "boundary_target" "linux_target_03" {
  name                     = "linux-target-03-ssh"
  description              = "linux-target-03"
  scope_id                 = var.boundary_project_scope_id
  type                     = "ssh"
  default_port             = 22
  session_connection_limit = -1
  ingress_worker_filter    = "\"ingress-worker\" in \"/tags/type\""
  egress_worker_filter     = "\"egress-worker\" in \"/tags/type\""

  host_source_ids = [
    boundary_host_set_plugin.linux_target_03_host_set.id,
  ]

  injected_application_credential_source_ids = [
    boundary_credential_ssh_private_key.linux_target_key.id,
  ]
}

####################################

resource "boundary_target" "linux_target_04" {
  name                     = "linux-target-04-ssh"
  description              = "linux-target-04"
  scope_id                 = var.boundary_project_scope_id
  type                     = "ssh"
  default_port             = 22
  session_connection_limit = -1
  ingress_worker_filter    = "\"ingress-worker\" in \"/tags/type\""
  egress_worker_filter     = "\"egress-worker\" in \"/tags/type\""

  host_source_ids = [
    boundary_host_set_plugin.linux_target_04_host_set.id,
  ]

  injected_application_credential_source_ids = [
    boundary_credential_ssh_private_key.linux_target_key.id,
  ]
}


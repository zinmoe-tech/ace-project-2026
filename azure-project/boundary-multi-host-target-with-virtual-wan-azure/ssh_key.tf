# -----------------------------------------------------------------------------
# SSH key — shared across all VMs (replaces the earlier per-role key setup;
# see SSH_KEYS.md). Created out-of-band: private half in key/general_key,
# public half registered in Azure as general-key
# (boundary-resource-uae-north) — looked up here rather than managed, so
# Terraform never regenerates/replaces a key you already have the private
# half of.
# -----------------------------------------------------------------------------

data "azurerm_ssh_public_key" "general" {
  name                = "general-key"
  resource_group_name = azurerm_resource_group.uae_north.name
}

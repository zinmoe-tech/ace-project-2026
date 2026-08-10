# -----------------------------------------------------------------------------
# Virtual Hub Connections — boundary-v-wan-hub
# Connects the three VNets to the hub. These already exist (created via the
# portal); imported into state rather than recreated.
# -----------------------------------------------------------------------------

resource "azurerm_virtual_hub_connection" "intermediate_worker" {
  name                      = "to-intermediate-worker-vn"
  virtual_hub_id            = data.azurerm_virtual_hub.boundary.id
  remote_virtual_network_id = azurerm_virtual_network.uae_north_vn.id
  internet_security_enabled = true
}

resource "azurerm_virtual_hub_connection" "target" {
  name                      = "to-target"
  virtual_hub_id            = data.azurerm_virtual_hub.boundary.id
  remote_virtual_network_id = azurerm_virtual_network.central_india_vn.id
  internet_security_enabled = true
}

resource "azurerm_virtual_hub_connection" "bastion" {
  name                      = "to-bastion-vn"
  virtual_hub_id            = data.azurerm_virtual_hub.boundary.id
  remote_virtual_network_id = azurerm_virtual_network.bastion_vn.id
  internet_security_enabled = true
}

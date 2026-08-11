# -----------------------------------------------------------------------------
# Virtual Hub Connections — boundary-v-wan-hub
# Connects intermediate-worker-vn, target-vn, and bastion-vn to the hub
# (see vhub_route_table.tf for the hub itself). All three associate with
# and propagate to v-wan-rt, so they share routes with each other via that
# table — pinned explicitly here so a portal edit can't silently point one
# connection at a different/empty route table and cut off the other two
# (that happened once already).
# -----------------------------------------------------------------------------

resource "azurerm_virtual_hub_connection" "intermediate_worker" {
  name                      = "to-intermediate-worker-vn"
  virtual_hub_id            = azurerm_virtual_hub.boundary.id
  remote_virtual_network_id = azurerm_virtual_network.uae_north_vn.id
  internet_security_enabled = true

  routing {
    associated_route_table_id = azurerm_virtual_hub_route_table.v-wan-rt.id
    propagated_route_table {
      route_table_ids = [azurerm_virtual_hub_route_table.v-wan-rt.id]
      labels          = ["v-wan-rt"]
    }
  }
}

resource "azurerm_virtual_hub_connection" "target" {
  name                      = "to-target"
  virtual_hub_id            = azurerm_virtual_hub.boundary.id
  remote_virtual_network_id = azurerm_virtual_network.central_india_vn.id
  internet_security_enabled = true

  routing {
    associated_route_table_id = azurerm_virtual_hub_route_table.v-wan-rt.id
    propagated_route_table {
      route_table_ids = [azurerm_virtual_hub_route_table.v-wan-rt.id]
      labels          = ["v-wan-rt"]
    }
  }
}

resource "azurerm_virtual_hub_connection" "bastion" {
  name                      = "to-bastion-vn"
  virtual_hub_id            = azurerm_virtual_hub.boundary.id
  remote_virtual_network_id = azurerm_virtual_network.bastion_vn.id
  internet_security_enabled = true

  routing {
    associated_route_table_id = azurerm_virtual_hub_route_table.v-wan-rt.id
    propagated_route_table {
      route_table_ids = [azurerm_virtual_hub_route_table.v-wan-rt.id]
      labels          = ["v-wan-rt"]
    }
  }
}

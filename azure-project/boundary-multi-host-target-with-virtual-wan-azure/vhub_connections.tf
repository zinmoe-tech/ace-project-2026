# -----------------------------------------------------------------------------
# Virtual Hub Connections — self-managed_intermediate_hub
# Connects all three regional VNets (Southeast Asia, Korea Central, Japan
# East) to the hub (see vhub_route_table.tf for the hub itself). Each VNet
# now hosts one self-managed-worker + intermediate-worker pair. All three
# associate with and propagate to self-managed_intermediate-rtb, so they
# share routes with each other via that table — pinned explicitly here so a
# portal edit can't silently point one connection at a different/empty
# route table and cut off the other two (that happened once already).
# -----------------------------------------------------------------------------

resource "azurerm_virtual_hub_connection" "southeast_asia" {
  name                      = "to-southeast-asia-vn"
  virtual_hub_id            = azurerm_virtual_hub.self-managed_intermediate_hub.id
  remote_virtual_network_id = azurerm_virtual_network.self_managed_vn.id
  internet_security_enabled = true

  routing {
    associated_route_table_id = azurerm_virtual_hub_route_table.self-managed_intermediate-rtb.id
    propagated_route_table {
      route_table_ids = [azurerm_virtual_hub_route_table.self-managed_intermediate-rtb.id]
      labels          = ["self-managed_intermediate-rtb"]
    }
  }
}

resource "azurerm_virtual_hub_connection" "korea_central" {
  name                      = "to-korea-central-vn"
  virtual_hub_id            = azurerm_virtual_hub.self-managed_intermediate_hub.id
  remote_virtual_network_id = azurerm_virtual_network.korea_central_vn.id
  internet_security_enabled = true

  routing {
    associated_route_table_id = azurerm_virtual_hub_route_table.self-managed_intermediate-rtb.id
    propagated_route_table {
      route_table_ids = [azurerm_virtual_hub_route_table.self-managed_intermediate-rtb.id]
      labels          = ["self-managed_intermediate-rtb"]
    }
  }
}

resource "azurerm_virtual_hub_connection" "japan_east" {
  name                      = "to-japan-east-vn"
  virtual_hub_id            = azurerm_virtual_hub.self-managed_intermediate_hub.id
  remote_virtual_network_id = azurerm_virtual_network.japan_east_vn.id
  internet_security_enabled = true

  routing {
    associated_route_table_id = azurerm_virtual_hub_route_table.self-managed_intermediate-rtb.id
    propagated_route_table {
      route_table_ids = [azurerm_virtual_hub_route_table.self-managed_intermediate-rtb.id]
      labels          = ["self-managed_intermediate-rtb"]
    }
  }
}

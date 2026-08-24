# -----------------------------------------------------------------------------
# Networking — Japan East (boundary-resource-japan-east)
# VNet: 10.3.0.0/16 | Subnet: 10.3.100.0/24
# Hosts self-managed-worker-03 + intermediate-worker-03.
# -----------------------------------------------------------------------------

resource "azurerm_virtual_network" "japan_east_vn" {
  name                = "boundary-japan-east-vn"
  address_space       = ["10.3.0.0/16"]
  location            = azurerm_resource_group.japan_east.location
  resource_group_name = azurerm_resource_group.japan_east.name
}

resource "azurerm_subnet" "japan_east_subnet" {
  name                 = "boundary-japan-east-subnet"
  resource_group_name  = azurerm_resource_group.japan_east.name
  virtual_network_name = azurerm_virtual_network.japan_east_vn.name
  address_prefixes     = ["10.3.100.0/24"]
}

# -----------------------------------------------------------------------------
# Networking — Southeast Asia (boundary-resource-southeast-asia)
# VNet: 10.1.0.0/16 | Subnet: 10.1.100.0/24
# Hosts self-managed-worker-01 + intermediate-worker-01.
# -----------------------------------------------------------------------------

resource "azurerm_virtual_network" "self_managed_vn" {
  name                = "boundary-self-managed-vn"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.southeast_asia.location
  resource_group_name = azurerm_resource_group.southeast_asia.name
}

resource "azurerm_subnet" "self_managed_subnet" {
  name                 = "boundary-self-managed-subnet"
  resource_group_name  = azurerm_resource_group.southeast_asia.name
  virtual_network_name = azurerm_virtual_network.self_managed_vn.name
  address_prefixes     = ["10.1.100.0/24"]
}

# -----------------------------------------------------------------------------
# Networking — Korea Central (boundary-resource-korea-central)
# VNet: 10.2.0.0/16 | Subnet: 10.2.100.0/24
# Hosts self-managed-worker-02 + intermediate-worker-02.
# -----------------------------------------------------------------------------

resource "azurerm_virtual_network" "korea_central_vn" {
  name                = "boundary-korea-central-vn"
  address_space       = ["10.2.0.0/16"]
  location            = azurerm_resource_group.korea_central.location
  resource_group_name = azurerm_resource_group.korea_central.name
}

resource "azurerm_subnet" "korea_central_subnet" {
  name                 = "korea-central-subnet"
  resource_group_name  = azurerm_resource_group.korea_central.name
  virtual_network_name = azurerm_virtual_network.korea_central_vn.name
  address_prefixes     = ["10.2.100.0/24"]
}

# -----------------------------------------------------------------------------
# Networking — Central India (boundary-resource-central-india)
# VNet: 10.1.0.0/16
# Subnets: intermediate (10.1.15.0/24)
# -----------------------------------------------------------------------------

resource "azurerm_virtual_network" "central_india_vn" {
  name                = "boundary-uae-central-india-vn"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.central_india.location
  resource_group_name = azurerm_resource_group.central_india.name
}

resource "azurerm_subnet" "central_india_intermediate_subnet" {
  name                 = "boundary-central-india-subnet"
  resource_group_name  = azurerm_resource_group.central_india.name
  virtual_network_name = azurerm_virtual_network.central_india_vn.name
  address_prefixes     = ["10.1.15.0/24"]
}

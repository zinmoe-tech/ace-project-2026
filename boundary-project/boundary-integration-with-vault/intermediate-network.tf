resource "azurerm_virtual_network" "boundary_intermediate_vn" {
  name                = "boundary-intermediate-vn"
  address_space       = ["10.2.0.0/16"]
  location            = azurerm_resource_group.east_us.location
  resource_group_name = azurerm_resource_group.east_us.name
}

resource "azurerm_subnet" "intermediate_subnet" {
  name                 = "boundary-intermediate-subnet"
  resource_group_name  = azurerm_resource_group.east_us.name
  virtual_network_name = azurerm_virtual_network.boundary_intermediate_vn.name
  address_prefixes     = ["10.2.100.0/24"]
}

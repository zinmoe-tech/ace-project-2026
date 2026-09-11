resource "azurerm_virtual_network" "boundary_ingress_vn" {
  name                = "boundary-ingress-vn"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.west_us_2.location
  resource_group_name = azurerm_resource_group.west_us_2.name
}

resource "azurerm_subnet" "ingress_subnet" {
  name                 = "boundary-ingress-subnet"
  resource_group_name  = azurerm_resource_group.west_us_2.name
  virtual_network_name = azurerm_virtual_network.boundary_ingress_vn.name
  address_prefixes     = ["10.1.100.0/24"]
}

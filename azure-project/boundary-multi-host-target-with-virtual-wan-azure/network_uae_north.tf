# -----------------------------------------------------------------------------
# Networking — UAE North (boundary-resource-uae-north)
# VNet: 172.20.0.0/16
# Subnets: intermediate (172.20.15.0/24)
# -----------------------------------------------------------------------------

resource "azurerm_virtual_network" "uae_north_vn" {
  name                = "boundary-uae-north-vn"
  address_space       = ["172.20.0.0/16"]
  location            = azurerm_resource_group.uae_north.location
  resource_group_name = azurerm_resource_group.uae_north.name
}

resource "azurerm_subnet" "uae_north_intermediate_subnet" {
  name                 = "uae-north-intermediate-subnet"
  resource_group_name  = azurerm_resource_group.uae_north.name
  virtual_network_name = azurerm_virtual_network.uae_north_vn.name
  address_prefixes     = ["172.20.15.0/24"]
}

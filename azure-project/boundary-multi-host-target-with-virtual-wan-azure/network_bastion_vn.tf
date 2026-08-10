# -----------------------------------------------------------------------------
# Networking — bastion-vm (UAE North, boundary-resource-uae-north)
# VNet: 10.169.0.0/16
# Subnets: bastion-vm (10.169.169.0/24)
# -----------------------------------------------------------------------------

resource "azurerm_virtual_network" "bastion_vn" {
  name                = "bastion-vn"
  address_space       = ["10.169.0.0/16"]
  location            = azurerm_resource_group.uae_north.location
  resource_group_name = azurerm_resource_group.uae_north.name
}

resource "azurerm_subnet" "bastion_vn_subnet" {
  name                 = "bastion-vn-subnet"
  resource_group_name  = azurerm_resource_group.uae_north.name
  virtual_network_name = azurerm_virtual_network.bastion_vn.name
  address_prefixes     = ["10.169.169.0/24"]
}

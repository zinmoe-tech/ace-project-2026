# Networking — UAE North (linux-target-rsg)
# VNet: 172.20.0.0/16 | Subnet: 172.20.10.0/24

resource "azurerm_virtual_network" "linux_target_vn" {
  name                = "linux-target-vn"
  address_space       = ["172.20.0.0/16"]
  location            = azurerm_resource_group.linux_target.location
  resource_group_name = azurerm_resource_group.linux_target.name
}

resource "azurerm_subnet" "linux_target_subnet" {
  name                 = "linux-target-subnet"
  resource_group_name  = azurerm_resource_group.linux_target.name
  virtual_network_name = azurerm_virtual_network.linux_target_vn.name
  address_prefixes     = ["172.20.10.0/24"]
}

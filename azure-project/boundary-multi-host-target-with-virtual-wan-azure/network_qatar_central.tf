# -----------------------------------------------------------------------------
# Networking — Qatar Central (boundary-self-managed-worker-rg)
# VNet: 192.168.0.0/16 | Subnet: 192.168.99.0/24
# -----------------------------------------------------------------------------

resource "azurerm_virtual_network" "self_managed_vn" {
  name                = "boundary-self-managed-vn"
  address_space       = ["192.168.0.0/16"]
  location            = azurerm_resource_group.qatar_central.location
  resource_group_name = azurerm_resource_group.qatar_central.name
}

resource "azurerm_subnet" "self_managed_subnet" {
  name                 = "boundary-self-managed-subnet"
  resource_group_name  = azurerm_resource_group.qatar_central.name
  virtual_network_name = azurerm_virtual_network.self_managed_vn.name
  address_prefixes     = ["192.168.99.0/24"]
}
# # -----------------------------------------------------------------------------
# # Networking — Central Israel (boundary-resource-central-israel)
# # VNet: 10.2.0.0/16
# # Subnets: intermediate (10.2.15.0/24)
# # -----------------------------------------------------------------------------

# resource "azurerm_virtual_network" "central_israel_vn" {
#   name                = "boundary-uae-central-israel-vn"
#   address_space       = ["10.2.0.0/16"]
#   location            = azurerm_resource_group.central_israel.location
#   resource_group_name = azurerm_resource_group.central_israel.name
# }

# resource "azurerm_subnet" "central_israel_intermediate_subnet" {
#   name                 = "boundary-central-israel-subnet"
#   resource_group_name  = azurerm_resource_group.central_israel.name
#   virtual_network_name = azurerm_virtual_network.central_israel_vn.name
#   address_prefixes     = ["10.2.15.0/24"]
# }

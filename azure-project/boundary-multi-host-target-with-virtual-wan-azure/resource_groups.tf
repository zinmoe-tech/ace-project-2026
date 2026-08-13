# -----------------------------------------------------------------------------
# Resource Groups — Southeast Asia, Korea Central, Japan East
# -----------------------------------------------------------------------------

resource "azurerm_resource_group" "southeast_asia" {
  name     = "boundary-resource-southeast-asia"
  location = "Southeast Asia"
}

resource "azurerm_resource_group" "korea_central" {
  name     = "boundary-resource-korea-central"
  location = "Korea Central"
}

resource "azurerm_resource_group" "japan_east" {
  name     = "boundary-resource-japan-east"
  location = "Japan East"
}

resource "azurerm_resource_group" "virtual_wan" {
  name     = "virtual-wan-rsg"
  location = "Korea Central"
}

# resource "azurerm_resource_group" "central_israel" {
#   name     = "boundary-resource-central-israel"
#   location = "Israel Central"
# }
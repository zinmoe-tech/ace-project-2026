# -----------------------------------------------------------------------------
# Resource Groups — West US 2 and East US
# -----------------------------------------------------------------------------

resource "azurerm_resource_group" "west_us_2" {
  name     = "boundary_resource-west_us_2"
  location = "West US 2"
}

resource "azurerm_resource_group" "east_us" {
  name     = "boundary_resource-east_us"
  location = "East US"
}
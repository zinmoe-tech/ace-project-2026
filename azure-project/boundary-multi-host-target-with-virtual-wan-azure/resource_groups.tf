# -----------------------------------------------------------------------------
# Resource Groups — Qatar Central, UAE North, Central India
# -----------------------------------------------------------------------------

resource "azurerm_resource_group" "qatar_central" {
  name     = "boundary-self-managed-worker-rg"
  location = "Qatar Central"
}

resource "azurerm_resource_group" "uae_north" {
  name     = "boundary-resource-uae-north"
  location = "UAE North"
}

resource "azurerm_resource_group" "central_india" {
  name     = "boundary-resource-central-india"
  location = "Central India"
}

# resource "azurerm_resource_group" "central_israel" {
#   name     = "boundary-resource-central-israel"
#   location = "Israel Central"
# }
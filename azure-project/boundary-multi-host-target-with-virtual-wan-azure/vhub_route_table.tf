# -----------------------------------------------------------------------------
# Virtual Hub Route Table — boundary-v-wan-hub (created via the portal, in
# virtual-wan-rsg — referenced by data source, not managed here).
# Empty for now: just the table + a label, no static routes. Associate it
# to the intermediate-worker hub connection once the routing policy is
# decided.
# -----------------------------------------------------------------------------

data "azurerm_virtual_hub" "boundary" {
  name                = "boundary-v-wan-hub"
  resource_group_name = "virtual-wan-rsg"
}

resource "azurerm_virtual_hub_route_table" "v-wan-rt" {
  name           = "v-wan-rt"
  virtual_hub_id = data.azurerm_virtual_hub.boundary.id
  labels         = ["v-wan-rt"]
}

# -----------------------------------------------------------------------------
# Virtual WAN + Hub — boundary-vwan / boundary-v-wan-hub (virtual-wan-rsg,
# UAE North). Connects intermediate-worker-vn, bastion-vn, and target-vn
# (see vhub_connections.tf) over the Microsoft backbone instead of VNet
# peering.
# -----------------------------------------------------------------------------

resource "azurerm_virtual_wan" "boundary" {
  name                = "boundary-vwan"
  resource_group_name = azurerm_resource_group.virtual_wan.name
  location            = azurerm_resource_group.virtual_wan.location
}

resource "azurerm_virtual_hub" "boundary" {
  name                = "boundary-v-wan-hub"
  resource_group_name = azurerm_resource_group.virtual_wan.name
  location            = azurerm_resource_group.virtual_wan.location
  virtual_wan_id      = azurerm_virtual_wan.boundary.id
  address_prefix      = "10.0.0.0/24"
}

# Empty for now: just the table + a label, no static routes. Associate it
# to a hub connection once the routing policy is decided — connections
# currently use the hub's built-in defaultRouteTable (see
# vhub_connections.tf).
resource "azurerm_virtual_hub_route_table" "v-wan-rt" {
  name           = "v-wan-rt"
  virtual_hub_id = azurerm_virtual_hub.boundary.id
  labels         = ["v-wan-rt"]
}

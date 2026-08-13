# -----------------------------------------------------------------------------
# Virtual WAN + Hub — self-managed_intermediate_vwan / boundary-v-wan-hub
# (virtual-wan-rsg, Korea Central). Connects the three regional VNets —
# Southeast Asia, Korea Central, Japan East — each hosting a
# self-managed-worker + intermediate-worker pair (see vhub_connections.tf)
# over the Microsoft backbone instead of VNet peering.
# -----------------------------------------------------------------------------

resource "azurerm_virtual_wan" "self-managed_intermediate_vwan" {
  name                = "self-managed_intermediate_vwan"
  resource_group_name = azurerm_resource_group.virtual_wan.name
  location            = azurerm_resource_group.virtual_wan.location
}

resource "azurerm_virtual_hub" "self-managed_intermediate_hub" {
  name                = "self-managed_intermediate_hub"
  resource_group_name = azurerm_resource_group.virtual_wan.name
  location            = azurerm_resource_group.virtual_wan.location
  virtual_wan_id      = azurerm_virtual_wan.self-managed_intermediate_vwan.id
  address_prefix      = "10.0.99.0/24"
}

# Empty for now: just the table + a label, no static routes. Associate it
# to a hub connection once the routing policy is decided — connections
# currently use the hub's built-in defaultRouteTable (see
# vhub_connections.tf).
resource "azurerm_virtual_hub_route_table" "self-managed_intermediate-rtb" {
  name           = "self-managed_intermediate-rtb"
  virtual_hub_id = azurerm_virtual_hub.self-managed_intermediate_hub.id
  labels         = ["self-managed_intermediate-rtb"]
}

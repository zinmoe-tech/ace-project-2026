# Virtual WAN — global-v-net-connection-wan (virtual-wan-rsg, Korea Central)
# All virtual-WAN-related resources live in this one file: WAN, hub, route
# tables, and connections.

# Step 1: the WAN itself.
resource "azurerm_virtual_wan" "global_v_net_connection_wan" {
  name                = "global-v-net-connection-wan"
  resource_group_name = azurerm_resource_group.virtual_wan.name
  location            = azurerm_resource_group.virtual_wan.location
}

# Step 2: the hub.
resource "azurerm_virtual_hub" "global_v_net_connection_hub" {
  name                = "global-v-net-connection-hub"
  resource_group_name = azurerm_resource_group.virtual_wan.name
  location            = azurerm_resource_group.virtual_wan.location
  virtual_wan_id      = azurerm_virtual_wan.global_v_net_connection_wan.id
  address_prefix      = "10.0.99.0/24"
}

# Step 3: the two route tables, empty for now. Routes get added once the
# connections below exist — linux-target-rtb's routes point at the 3
# regional connections (no cycle, since it's not associated with those same
# connections); global-v-net-connection-rtb stays propagation-only — it's
# associated with the very connections its routes would need to point at,
# which is a circular dependency in Terraform.
resource "azurerm_virtual_hub_route_table" "global_v_net_connection_rtb" {
  name           = "global-v-net-connection-rtb"
  virtual_hub_id = azurerm_virtual_hub.global_v_net_connection_hub.id
  labels         = ["global-v-net-connection-rtb"]
}

resource "azurerm_virtual_hub_route_table" "linux_target" {
  name           = "linux-target-rtb"
  virtual_hub_id = azurerm_virtual_hub.global_v_net_connection_hub.id
  labels         = ["linux-target-rtb"]

  # Step 5: routes to the three intermediate workers' own IPs (not their
  # whole /24, and not the self-managed-workers or bastion sharing those
  # subnets) — mirrors the NSG's own scoping in vm_linux_target-01.tf.
  route {
    name              = "to-intermediate-worker-01"
    destinations_type = "CIDR"
    destinations      = ["10.1.100.5/32"]
    next_hop_type     = "ResourceId"
    next_hop          = azurerm_virtual_hub_connection.southeast_asia.id
  }

  route {
    name              = "to-intermediate-worker-02"
    destinations_type = "CIDR"
    destinations      = ["10.2.100.5/32"]
    next_hop_type     = "ResourceId"
    next_hop          = azurerm_virtual_hub_connection.korea_central.id
  }

  route {
    name              = "to-intermediate-worker-03"
    destinations_type = "CIDR"
    destinations      = ["10.3.100.5/32"]
    next_hop_type     = "ResourceId"
    next_hop          = azurerm_virtual_hub_connection.japan_east.id
  }
}

# Step 4: the 4 VNet connections. Southeast Asia, Korea Central, and Japan
# East associate with and propagate to global-v-net-connection-rtb, so they
# share routes with each other via that table. linux-target-vn stays
# narrow: associated with linux-target-rtb only, but still propagates into
# global-v-net-connection-rtb too, so the regional side learns a route back
# to 172.20.10.0/24.
resource "azurerm_virtual_hub_connection" "southeast_asia" {
  name                      = "to-southeast-asia-vn"
  virtual_hub_id            = azurerm_virtual_hub.global_v_net_connection_hub.id
  remote_virtual_network_id = azurerm_virtual_network.self_managed_vn.id
  internet_security_enabled = true

  routing {
    associated_route_table_id = azurerm_virtual_hub_route_table.global_v_net_connection_rtb.id
    propagated_route_table {
      route_table_ids = [azurerm_virtual_hub_route_table.global_v_net_connection_rtb.id]
      labels          = ["global-v-net-connection-rtb"]
    }
  }
}

resource "azurerm_virtual_hub_connection" "korea_central" {
  name                      = "to-korea-central-vn"
  virtual_hub_id            = azurerm_virtual_hub.global_v_net_connection_hub.id
  remote_virtual_network_id = azurerm_virtual_network.korea_central_vn.id
  internet_security_enabled = true

  routing {
    associated_route_table_id = azurerm_virtual_hub_route_table.global_v_net_connection_rtb.id
    propagated_route_table {
      route_table_ids = [azurerm_virtual_hub_route_table.global_v_net_connection_rtb.id]
      labels          = ["global-v-net-connection-rtb"]
    }
  }
}

resource "azurerm_virtual_hub_connection" "japan_east" {
  name                      = "to-japan-east-vn"
  virtual_hub_id            = azurerm_virtual_hub.global_v_net_connection_hub.id
  remote_virtual_network_id = azurerm_virtual_network.japan_east_vn.id
  internet_security_enabled = true

  routing {
    associated_route_table_id = azurerm_virtual_hub_route_table.global_v_net_connection_rtb.id
    propagated_route_table {
      route_table_ids = [azurerm_virtual_hub_route_table.global_v_net_connection_rtb.id]
      labels          = ["global-v-net-connection-rtb"]
    }
  }
}

resource "azurerm_virtual_hub_connection" "linux_target" {
  name                      = "to-linux-target-vn"
  virtual_hub_id            = azurerm_virtual_hub.global_v_net_connection_hub.id
  remote_virtual_network_id = azurerm_virtual_network.linux_target_vn.id
  internet_security_enabled = true

  routing {
    associated_route_table_id = azurerm_virtual_hub_route_table.linux_target.id
    propagated_route_table {
      route_table_ids = [
        azurerm_virtual_hub_route_table.linux_target.id,
        azurerm_virtual_hub_route_table.global_v_net_connection_rtb.id,
      ]
      labels = ["linux-target-rtb"]
    }
  }
}

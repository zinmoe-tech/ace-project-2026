# -----------------------------------------------------------------------------
# Security Group — Southeast Asia (10.1.100.0/24)
# Shared by self-managed-worker-01 and intermediate-worker-01 (same subnet).
# Inbound SSH (tcp/22) from anywhere, outbound TCP (all ports) to anywhere,
# plus ICMP to/from the other two regions' VNets for ping testing over the
# v-wan hub (see vhub_connections.tf).
# -----------------------------------------------------------------------------

resource "azurerm_network_security_group" "self_managed_worker_nsgp" {
  name                = "boundary-southeast-asia-nsg"
  location            = azurerm_resource_group.southeast_asia.location
  resource_group_name = azurerm_resource_group.southeast_asia.name

  security_rule {
    name                       = "ssh-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "tcp-outbound-all"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "icmp-inbound-from-vwan-vnets"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefixes    = ["10.2.0.0/16", "10.3.0.0/16"]
    destination_address_prefix = "10.1.0.0/16"
  }

  security_rule {
    name                         = "icmp-outbound-to-vwan-vnets"
    priority                     = 210
    direction                    = "Outbound"
    access                       = "Allow"
    protocol                     = "Icmp"
    source_port_range            = "*"
    destination_port_range       = "*"
    source_address_prefix        = "10.1.0.0/16"
    destination_address_prefixes = ["10.2.0.0/16", "10.3.0.0/16"]
  }
}

resource "azurerm_subnet_network_security_group_association" "self_managed_worker" {
  subnet_id                 = azurerm_subnet.self_managed_subnet.id
  network_security_group_id = azurerm_network_security_group.self_managed_worker_nsgp.id
}

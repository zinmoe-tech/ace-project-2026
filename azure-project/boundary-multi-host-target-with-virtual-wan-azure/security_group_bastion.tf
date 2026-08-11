# -----------------------------------------------------------------------------
# Security Group — bastion (UAE North, 10.169.169.0/24)
# Outbound SSH (tcp/22) to the intermediate subnet only. Paired with the
# inbound rule on intermediate_worker_nsgp in
# security_group_intermediate_worker.tf.
# -----------------------------------------------------------------------------

resource "azurerm_network_security_group" "bastion_nsgp" {
  name                = "boundary-bastion-nsg"
  location            = azurerm_resource_group.uae_north.location
  resource_group_name = azurerm_resource_group.uae_north.name

  security_rule {
    name                       = "ssh-inbound-from-internet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "10.169.169.0/24"
  }
  security_rule {
    name                       = "ssh-outbound-to-intermediate"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.169.169.0/24"
    destination_address_prefix = "172.20.15.0/24"
  }

  # Ping testing across the three v-wan-connected VNets (bastion,
  # intermediate-worker, target). Both directions since either side may
  # initiate.
  security_rule {
    name                       = "icmp-inbound-from-vwan-vnets"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefixes    = ["172.20.15.0/24", "10.1.15.0/24"]
    destination_address_prefix = "10.169.169.0/24"
  }

  security_rule {
    name                         = "icmp-outbound-to-vwan-vnets"
    priority                     = 210
    direction                    = "Outbound"
    access                       = "Allow"
    protocol                     = "Icmp"
    source_port_range            = "*"
    destination_port_range       = "*"
    source_address_prefix        = "10.169.169.0/24"
    destination_address_prefixes = ["172.20.15.0/24", "10.1.15.0/24"]
  }
}

resource "azurerm_subnet_network_security_group_association" "bastion" {
  subnet_id                 = azurerm_subnet.bastion_vn_subnet.id
  network_security_group_id = azurerm_network_security_group.bastion_nsgp.id
}

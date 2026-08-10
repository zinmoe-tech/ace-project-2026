# -----------------------------------------------------------------------------
# Security Group — intermediate-worker (UAE North, 172.20.15.0/24)
# Outbound only, SSH (tcp/22) to the other regions' intermediate/worker
# subnets: Central India, Central Israel, and the Qatar self-managed worker.
# -----------------------------------------------------------------------------

resource "azurerm_network_security_group" "intermediate_worker_nsgp" {
  name                = "boundary-intermediate-worker-nsg"
  location            = azurerm_resource_group.uae_north.location
  resource_group_name = azurerm_resource_group.uae_north.name

  security_rule {
    name                       = "ssh-outbound-central-india"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "172.20.15.0/24"
    destination_address_prefix = "10.1.15.0/24"
  }

  security_rule {
    name                       = "ssh-outbound-central-israel"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "172.20.15.0/24"
    destination_address_prefix = "10.2.15.0/24"
  }

  security_rule {
    name                       = "ssh-outbound-qatar-self-managed"
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "172.20.15.0/24"
    destination_address_prefix = "192.168.99.0/24"
  }

  security_rule {
    name                       = "ssh-inbound-from-bastion"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.169.169.0/24"
    destination_address_prefix = "172.20.15.0/24"
  }
}

resource "azurerm_subnet_network_security_group_association" "intermediate_worker" {
  subnet_id                 = azurerm_subnet.uae_north_intermediate_subnet.id
  network_security_group_id = azurerm_network_security_group.intermediate_worker_nsgp.id
}

# Also attached directly to each worker's NIC (redundant with the
# subnet-level association above, same rules either way) so the NSG shows up
# on the VM's own network interface in the portal, not just the subnet.
# resource "azurerm_network_interface_security_group_association" "intermediate_worker_01" {
#   network_interface_id      = azurerm_network_interface.intermediate_worker_01.id
#   network_security_group_id = azurerm_network_security_group.intermediate_worker_nsgp.id
# }

# resource "azurerm_network_interface_security_group_association" "intermediate_worker_02" {
#   network_interface_id      = azurerm_network_interface.intermediate_worker_02.id
#   network_security_group_id = azurerm_network_security_group.intermediate_worker_nsgp.id
# }

# -----------------------------------------------------------------------------
# Security Group — self-managed-worker (Qatar Central, 192.168.99.0/24)
# Inbound SSH (tcp/22) from anywhere, outbound TCP (all ports) to anywhere.
# -----------------------------------------------------------------------------

resource "azurerm_network_security_group" "self_managed_worker_nsgp" {
  name                = "boundary-self-managed-worker-nsg"
  location            = azurerm_resource_group.qatar_central.location
  resource_group_name = azurerm_resource_group.qatar_central.name

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
}

resource "azurerm_subnet_network_security_group_association" "self_managed_worker" {
  subnet_id                 = azurerm_subnet.self_managed_subnet.id
  network_security_group_id = azurerm_network_security_group.self_managed_worker_nsgp.id
}

# Also attached directly to each worker's NIC (redundant with the
# subnet-level association above, same rules either way) so the NSG shows up
# on the VM's own network interface in the portal, not just the subnet.
resource "azurerm_network_interface_security_group_association" "self_managed_worker_01" {
  network_interface_id      = azurerm_network_interface.self_managed_worker_01.id
  network_security_group_id = azurerm_network_security_group.self_managed_worker_nsgp.id
}

resource "azurerm_network_interface_security_group_association" "self_managed_worker_02" {
  network_interface_id      = azurerm_network_interface.self_managed_worker_02.id
  network_security_group_id = azurerm_network_security_group.self_managed_worker_nsgp.id
}

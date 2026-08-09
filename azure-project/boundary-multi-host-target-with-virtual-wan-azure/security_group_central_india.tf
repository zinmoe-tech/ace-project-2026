# -----------------------------------------------------------------------------
# Security Group — Central India (10.1.15.0/24)
# Inbound SSH (tcp/22) only from the UAE North intermediate VMs
# (intermediate-worker-01/-02, 172.20.15.4 and .5).
# -----------------------------------------------------------------------------

resource "azurerm_network_security_group" "central_india_nsgp" {
  name                = "boundary-central-india-nsg"
  location            = azurerm_resource_group.central_india.location
  resource_group_name = azurerm_resource_group.central_india.name

  security_rule {
    name                       = "ssh-inbound-from-intermediate-workers"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = ["172.20.15.4/32", "172.20.15.5/32"]
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "central_india" {
  subnet_id                 = azurerm_subnet.central_india_intermediate_subnet.id
  network_security_group_id = azurerm_network_security_group.central_india_nsgp.id
}

# Also attached directly to the target VM's NIC (redundant with the
# subnet-level association above, same rules either way) so the NSG shows up
# on the VM's own network interface in the portal, not just the subnet.
resource "azurerm_network_interface_security_group_association" "linux_target_01" {
  network_interface_id      = azurerm_network_interface.linux_target_01.id
  network_security_group_id = azurerm_network_security_group.central_india_nsgp.id
}

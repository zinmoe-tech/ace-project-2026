# VM — intermediate-worker-03 (Japan East)

# No public IP.
resource "azurerm_network_interface" "intermediate_worker_03" {
  name                = "intermediate-worker-03-nic"
  location            = azurerm_resource_group.japan_east.location
  resource_group_name = azurerm_resource_group.japan_east.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.japan_east_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.3.100.5"
  }
}

# No 9202 inbound: it only dials out to self-managed workers, never listens.
resource "azurerm_network_security_group" "intermediate_worker_03" {
  name                = "intermediate-worker-03-nsg"
  location            = azurerm_resource_group.japan_east.location
  resource_group_name = azurerm_resource_group.japan_east.name

  # ssh access
  security_rule {
    name                       = "ssh-inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "10.3.100.5"
  }

  # outbound to self-managed workers only (initial_upstreams mesh)
  security_rule {
    name                         = "worker-mesh-outbound"
    priority                     = 100
    direction                    = "Outbound"
    access                       = "Allow"
    protocol                     = "Tcp"
    source_port_range            = "*"
    destination_port_range       = "9202"
    source_address_prefix        = "10.3.100.5"
    destination_address_prefixes = ["10.1.100.4", "10.2.100.4", "10.3.100.4"]
  }

  # ssh outbound to the linux target
  security_rule {
    name                       = "ssh-outbound-to-linux-target"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "172.20.10.0/24"
  }

  # icmp
  security_rule {
    name                       = "icmp-inbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # icmp
  security_rule {
    name                       = "icmp-outbound"
    priority                   = 210
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # block everything else outbound
  security_rule {
    name                       = "deny-all-other-outbound"
    priority                   = 4096
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "intermediate_worker_03" {
  network_interface_id      = azurerm_network_interface.intermediate_worker_03.id
  network_security_group_id = azurerm_network_security_group.intermediate_worker_03.id
}

# Standard_D2as_v6 (2 vCPU), same size as self-managed-worker-03. No zone:
# this SKU has no capacity in zone 1 in Japan East, and zone 3 repeatedly hit
# ZonalAllocationFailed, so this is left unzoned to let Azure place it
# wherever there's room. On-demand.
resource "azurerm_linux_virtual_machine" "intermediate_worker_03" {
  name                = "intermediate-worker-03"
  location            = azurerm_resource_group.japan_east.location
  resource_group_name = azurerm_resource_group.japan_east.name
  size                = "Standard_D2as_v6"
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.intermediate_worker_03.id,
  ]

  disable_password_authentication   = true
  vm_agent_platform_updates_enabled = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = data.azurerm_ssh_public_key.general.public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

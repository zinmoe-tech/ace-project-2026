# VM — linux-target-01 (UAE North)

# No public IP: only reachable from the intermediate workers (see NSG below).
resource "azurerm_network_interface" "linux_target_01" {
  name                = "linux-target-01-nic"
  location            = azurerm_resource_group.linux_target.location
  resource_group_name = azurerm_resource_group.linux_target.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.linux_target_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "172.20.10.4"
  }
}

# ssh access from intermediate workers only
resource "azurerm_network_security_group" "linux_target" {
  name                = "linux-target-01-nsg"
  location            = azurerm_resource_group.linux_target.location
  resource_group_name = azurerm_resource_group.linux_target.name

  security_rule {
    name                       = "ssh-inbound-from-intermediate-workers"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = ["10.1.100.5", "10.2.100.5", "10.3.100.5"]
    destination_address_prefix = "*"
  }

  # icmp
  security_rule {
    name                       = "icmp-inbound"
    priority                   = 110
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
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "linux_target_01" {
  network_interface_id      = azurerm_network_interface.linux_target_01.id
  network_security_group_id = azurerm_network_security_group.linux_target.id
}

# Standard_F1als_v7 (1 vCPU, 2 GiB): cheapest unrestricted SKU for this
# subscription in UAE North — B-series (usually cheaper still) is
# restricted here. Spot: UAE North's 3-vCPU LowPriority quota is
# completely unused, so this fits with room to spare.
resource "azurerm_linux_virtual_machine" "linux_target_01" {
  name                = "linux-target-01"
  location            = azurerm_resource_group.linux_target.location
  resource_group_name = azurerm_resource_group.linux_target.name
  size                = "Standard_F1als_v7"
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.linux_target_01.id,
  ]

  disable_password_authentication   = true
  vm_agent_platform_updates_enabled = false

  priority        = "Spot"
  eviction_policy = "Deallocate"
  max_bid_price   = -1

  admin_ssh_key {
    username   = "azureuser"
    public_key = data.azurerm_ssh_public_key.linux_target.public_key
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

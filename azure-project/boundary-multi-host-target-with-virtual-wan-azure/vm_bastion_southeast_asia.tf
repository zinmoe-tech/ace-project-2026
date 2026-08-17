# VM — bastion (Southeast Asia)

resource "azurerm_public_ip" "bastion_southeast_asia" {
  name                = "bastion-southeast-asia-pip"
  location            = azurerm_resource_group.southeast_asia.location
  resource_group_name = azurerm_resource_group.southeast_asia.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "bastion_southeast_asia" {
  name                = "bastion-southeast-asia-nic"
  location            = azurerm_resource_group.southeast_asia.location
  resource_group_name = azurerm_resource_group.southeast_asia.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.self_managed_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.1.100.6"
    public_ip_address_id          = azurerm_public_ip.bastion_southeast_asia.id
  }
}

# Jump box only: SSH in, nothing else listens.
resource "azurerm_network_security_group" "bastion_southeast_asia" {
  name                = "bastion-southeast-asia-nsg"
  location            = azurerm_resource_group.southeast_asia.location
  resource_group_name = azurerm_resource_group.southeast_asia.name

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
    destination_address_prefix = "*"
  }

  # general egress (ssh onward to other VMs, package updates, etc.)
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
}

resource "azurerm_network_interface_security_group_association" "bastion_southeast_asia" {
  network_interface_id      = azurerm_network_interface.bastion_southeast_asia.id
  network_security_group_id = azurerm_network_security_group.bastion_southeast_asia.id
}

# Standard_DC1s_v3 (1 vCPU): only unrestricted sub-2-vCPU SKU in Southeast
# Asia — needed since self-managed-worker-01 (1) + intermediate-worker-01 (2)
# already use all but 1 vCPU of the region's 4-core quota. On-demand.
resource "azurerm_linux_virtual_machine" "bastion_southeast_asia" {
  name                = "bastion-southeast-asia"
  location            = azurerm_resource_group.southeast_asia.location
  resource_group_name = azurerm_resource_group.southeast_asia.name
  size                = "Standard_DC1s_v3"
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.bastion_southeast_asia.id,
  ]

  disable_password_authentication   = true
  vm_agent_platform_updates_enabled = false

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

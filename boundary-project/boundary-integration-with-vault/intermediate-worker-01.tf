# VM — intermediate-worker-01 (East US)

resource "azurerm_public_ip" "intermediate_worker_01" {
  name                = "intermediate-worker-01-pip"
  location            = azurerm_resource_group.east_us.location
  resource_group_name = azurerm_resource_group.east_us.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "intermediate_worker_01" {
  name                = "intermediate-worker-01-nic"
  location            = azurerm_resource_group.east_us.location
  resource_group_name = azurerm_resource_group.east_us.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.intermediate_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.2.100.4"
    public_ip_address_id          = azurerm_public_ip.intermediate_worker_01.id
  }
}

# No 9202 inbound: it only dials out to self-managed workers, never listens.
resource "azurerm_network_security_group" "intermediate_worker_01_nsg" {
  name                = "intermediate-worker-01-nsg"
  location            = azurerm_resource_group.east_us.location
  resource_group_name = azurerm_resource_group.east_us.name

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

  # outbound to self-managed workers only (initial_upstreams mesh)
  security_rule {
    name                   = "ssh-outbound-to-boundary-controller"
    priority               = 100
    direction              = "Outbound"
    access                 = "Allow"
    protocol               = "Tcp"
    source_port_range      = "*"
    destination_port_range = "9202"
    source_address_prefix  = "*"
    destination_address_prefixes = [
      azurerm_public_ip.ingress_worker_01.ip_address,
      azurerm_public_ip.ingress_worker_02.ip_address,
    ]
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

resource "azurerm_network_interface_security_group_association" "intermediate_worker_01" {
  network_interface_id      = azurerm_network_interface.intermediate_worker_01.id
  network_security_group_id = azurerm_network_security_group.intermediate_worker_01_nsg.id
}

# Standard_DC2s_v3: 2-vCPU confidential compute worker SKU.
resource "azurerm_linux_virtual_machine" "intermediate_worker_01" {
  name                = "intermediate-worker-01"
  location            = azurerm_resource_group.east_us.location
  resource_group_name = azurerm_resource_group.east_us.name
  size                = "Standard_DC2s_v3"
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.intermediate_worker_01.id,
  ]

  disable_password_authentication   = true
  vm_agent_platform_updates_enabled = false

  admin_ssh_key {
    username   = "azureuser"
    public_key = azurerm_ssh_public_key.general.public_key
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

# VM — self-managed-worker-01 (Southeast Asia)

resource "azurerm_public_ip" "self_managed_worker_01" {
  name                = "self-managed-worker-01-pip"
  location            = azurerm_resource_group.southeast_asia.location
  resource_group_name = azurerm_resource_group.southeast_asia.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "self_managed_worker_01" {
  name                = "self-managed-worker-01-nic"
  location            = azurerm_resource_group.southeast_asia.location
  resource_group_name = azurerm_resource_group.southeast_asia.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.self_managed_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.1.100.4"
    public_ip_address_id          = azurerm_public_ip.self_managed_worker_01.id
  }
}

# Boundary clients (CLI/browser) dial this worker's public IP on 9202
# directly for the proxy session — confirmed by a real session teardown
# timeout hitting self-managed-worker-02's public IP on 9202 when that
# inbound rule was missing. Outbound to HCP is still locked to the 3 known
# proxy IPs below (DNS-resolved from
# <cluster-id>.proxy.boundary.hashicorp.cloud, not a published static
# range — re-check them if HCP connectivity ever breaks unexpectedly).
resource "azurerm_network_security_group" "self_managed_worker_01" {
  name                = "self-managed-worker-01-nsg"
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

  # boundary proxy inbound — clients dial this directly
  security_rule {
    name                       = "boundary-proxy-inbound"
    priority                   = 105
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9202"
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

  # outbound to HCP Boundary (proxy, tcp/9202)
  security_rule {
    name                         = "hcp-proxy-outbound"
    priority                     = 100
    direction                    = "Outbound"
    access                       = "Allow"
    protocol                     = "Tcp"
    source_port_range            = "*"
    destination_port_range       = "*"
    source_address_prefix        = "*"
    destination_address_prefixes = ["3.224.38.35", "3.233.88.122", "54.172.227.234"]
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

resource "azurerm_network_interface_security_group_association" "self_managed_worker_01" {
  network_interface_id      = azurerm_network_interface.self_managed_worker_01.id
  network_security_group_id = azurerm_network_security_group.self_managed_worker_01.id
}

# Standard_DC1s_v3: downsized from Standard_DC2s_v3 (2 vCPU) to free a core
# for the bastion — Southeast Asia's 4-core regional quota had no headroom
# and self-service quota increases aren't available on this subscription.
# Zone 2: the only zone with capacity for this SKU family in Southeast
# Asia — zone 1 hits OverconstrainedZonalAllocationRequest. On-demand.
resource "azurerm_linux_virtual_machine" "self_managed_worker_01" {
  name                = "self-managed-worker-01"
  location            = azurerm_resource_group.southeast_asia.location
  resource_group_name = azurerm_resource_group.southeast_asia.name
  size                = "Standard_DC1s_v3"
  admin_username      = "azureuser"
  zone                = "2"

  network_interface_ids = [
    azurerm_network_interface.self_managed_worker_01.id,
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

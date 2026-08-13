# -----------------------------------------------------------------------------
# VM — self-managed-worker-01 (Southeast Asia, 10.1.100.0/24)
# Paired with intermediate-worker-01 in the same region/subnet (see
# vm_intermediate_worker-01.tf). Standard_D2as_v6 (matching every other VM
# in this config) — pinned to zone 1, since D2as_v6/D2as_v7/F2s_v2 all hit
# Spot capacity restrictions unzoned, and Spot capacity is often
# zone-specific. Azure Spot, ubuntu-24_04-lts. Unlike intermediate-worker,
# this one has a public IP.
# SSH key: data.azurerm_ssh_public_key.general, see ssh_key.tf. NSG rules
# come from the subnet-level association in
# security_group_self_managed_worker.tf (plus the NIC-level association
# below).
# -----------------------------------------------------------------------------

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

resource "azurerm_linux_virtual_machine" "self_managed_worker_01" {
  name                = "self-managed-worker-01"
  location            = azurerm_resource_group.southeast_asia.location
  resource_group_name = azurerm_resource_group.southeast_asia.name
  size                = "Standard_D2as_v6"
  admin_username      = "azureuser"
  zone                = "3"

  network_interface_ids = [
    azurerm_network_interface.self_managed_worker_01.id,
  ]

  disable_password_authentication   = true
  vm_agent_platform_updates_enabled = false

  admin_ssh_key {
    username   = "azureuser"
    public_key = data.azurerm_ssh_public_key.general.public_key
  }

  # Azure Spot: evicted only on capacity, never on price (max_bid_price = -1
  # means pay up to the standard on-demand rate, not evicted for price).
  priority        = "Spot"
  eviction_policy = "Deallocate"
  max_bid_price   = -1

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

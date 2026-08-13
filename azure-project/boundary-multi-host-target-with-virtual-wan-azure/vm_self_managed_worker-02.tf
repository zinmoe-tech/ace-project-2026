# -----------------------------------------------------------------------------
# VM — self-managed-worker-02 (Korea Central, 10.2.100.0/24)
# Paired with intermediate-worker-02 in the same region/subnet (see
# vm_intermediate_worker-02.tf). Standard_D2s_v5 (2 vCPU, 8 GiB, Intel) —
# picked specifically for Korea Central. Azure Spot, ubuntu-24_04-lts,
# public IP. SSH key: data.azurerm_ssh_public_key.general, see ssh_key.tf.
# -----------------------------------------------------------------------------

resource "azurerm_public_ip" "self_managed_worker_02" {
  name                = "self-managed-worker-02-pip"
  location            = azurerm_resource_group.korea_central.location
  resource_group_name = azurerm_resource_group.korea_central.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "self_managed_worker_02" {
  name                = "self-managed-worker-02-nic"
  location            = azurerm_resource_group.korea_central.location
  resource_group_name = azurerm_resource_group.korea_central.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.korea_central_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.2.100.4"
    public_ip_address_id          = azurerm_public_ip.self_managed_worker_02.id
  }
}

resource "azurerm_linux_virtual_machine" "self_managed_worker_02" {
  name                = "self-managed-worker-02"
  location            = azurerm_resource_group.korea_central.location
  resource_group_name = azurerm_resource_group.korea_central.name
  size                = "Standard_D2s_v5"
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.self_managed_worker_02.id,
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

# -----------------------------------------------------------------------------
# VM — intermediate-worker-03 (Japan East, 10.3.100.0/24)
# Paired with self-managed-worker-03 in the same region/subnet (see
# vm_self_managed_worker-03.tf). Standard_D2as_v6 (2 vCPU), same size as
# self-managed-worker-03 — used uniformly across every VM in this config.
# Both VMs on Spot means this region's two VMs total 4 vCPU against a
# 3-vCPU Low-priority quota — a quota increase is required before this
# applies cleanly. No public IP. SSH key:
# data.azurerm_ssh_public_key.general, see ssh_key.tf.
# -----------------------------------------------------------------------------

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

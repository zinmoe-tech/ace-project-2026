# -----------------------------------------------------------------------------
# VM — intermediate-worker (UAE North, 172.20.15.0/24)
# Standard_D2as_v7 (2 vCPU, 8 GiB), Azure Spot, no public IP. NSG rules come
# from the subnet-level association in security_group_intermediate_worker.tf.
# -----------------------------------------------------------------------------

# Key pair already exists in Azure (created out-of-band, private half held
# locally) — looked up here rather than managed, so Terraform never
# regenerates/replaces a key you already have the private half of.
data "azurerm_ssh_public_key" "intermediate_remote" {
  name                = "intermediate-remote-key"
  resource_group_name = azurerm_resource_group.uae_north.name
}

resource "azurerm_network_interface" "intermediate_worker_01" {
  name                = "intermediate-worker-01-nic"
  location            = azurerm_resource_group.uae_north.location
  resource_group_name = azurerm_resource_group.uae_north.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.uae_north_intermediate_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "172.20.15.4"
  }
}

resource "azurerm_linux_virtual_machine" "intermediate_worker_01" {
  name                = "intermediate-worker-01"
  location            = azurerm_resource_group.uae_north.location
  resource_group_name = azurerm_resource_group.uae_north.name
  size                = "Standard_D2as_v7"
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.intermediate_worker_01.id,
  ]

  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = data.azurerm_ssh_public_key.intermediate_remote.public_key
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

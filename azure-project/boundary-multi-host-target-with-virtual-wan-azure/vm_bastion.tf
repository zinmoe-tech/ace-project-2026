# -----------------------------------------------------------------------------
# VM — bastion (UAE North, 10.169.169.0/24)
# Standard_F1as_v7 (1 vCPU), Azure Spot, ubuntu-24_04-lts. Has a public IP
# (unlike intermediate-worker). Sized down from D2as_v7 (2 vCPU) to fit UAE
# North's Low-priority vCPU quota (3 total; intermediate-worker-01 alone
# uses 2) without requesting a quota increase.
# SSH key: data.azurerm_ssh_public_key.general, see ssh_key.tf. NSG rules
# come from the subnet-level association in security_group_bastion.tf.
#
# Harmless drift: vm_agent_platform_updates_enabled shows true -> false on
# every plan (Azure VM Agent auto-upgrade setting, unset here).
# -----------------------------------------------------------------------------

resource "azurerm_public_ip" "bastion" {
  name                = "bastion-pip"
  location            = azurerm_resource_group.uae_north.location
  resource_group_name = azurerm_resource_group.uae_north.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "bastion" {
  name                = "bastion-nic"
  location            = azurerm_resource_group.uae_north.location
  resource_group_name = azurerm_resource_group.uae_north.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.bastion_vn_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.169.169.4"
    public_ip_address_id          = azurerm_public_ip.bastion.id
  }
}

resource "azurerm_linux_virtual_machine" "bastion" {
  name                = "bastion"
  location            = azurerm_resource_group.uae_north.location
  resource_group_name = azurerm_resource_group.uae_north.name
  size                = "Standard_F1as_v7"
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.bastion.id,
  ]

  disable_password_authentication = true

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

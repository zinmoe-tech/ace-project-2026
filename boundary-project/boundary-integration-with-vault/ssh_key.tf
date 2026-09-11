# SSH key — shared by the lab VMs. Terraform registers the public half in Azure.
# Keep the private key only on your machine.
resource "azurerm_ssh_public_key" "general" {
  name                = var.azure_ssh_public_key_name
  resource_group_name = var.azure_ssh_public_key_resource_group_name
  location            = azurerm_resource_group.west_us_2.location
  public_key          = file("${path.module}/key/general_key.pub")
}

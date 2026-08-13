# SSH keys — shared key setup

All VMs use a single shared key, `general-key`. Keypair lives locally in
`keys/` (gitignored via `**/keys/` in `azure-project/.gitignore`); the public
half is uploaded to Azure as a `Microsoft.Compute/sshPublicKeys` resource and
looked up from Terraform via a `data` block (out-of-band pattern — Terraform
never manages the private key, so it never regenerates/replaces a key you
hold the private half of).

**Azure requires RSA** for `admin_ssh_key` on `azurerm_linux_virtual_machine`
(ed25519 uploads to `az sshkey` fine, but VM creation rejects it with
`the provided ssh-ed25519 SSH key is not supported`). `general-key` is
RSA 4096-bit.

| Private key            | Public key                  | Azure resource | Resource group                     |
|--------------------------|--------------------------------|-----------------|---------------------------------------|
| `keys/general_key`     | `keys/general_key.pub`      | `general-key`  | `boundary-resource-korea-central`  |

This replaces the earlier per-role setup (`self-managed-worker-key`,
`intermediate-worker-key`, `targets-key`, `bastion-key`) — those Azure SSH
key resources were tied to regions/resource groups that no longer exist.

**Note:** the key currently lives in `boundary-resource-korea-central`
(originally uploaded when that resource group was still named
`boundary-resource-uae-north`, before the Qatar/UAE-North/Central-India →
Southeast-Asia/Korea-Central/Japan-East region migration). If this resource
group is ever destroyed and recreated, re-upload the existing local public
key rather than generating a new one:

```bash
az sshkey create --name general-key --resource-group boundary-resource-korea-central \
  --location "Korea Central" --public-key "@keys/general_key.pub"
```

## Terraform wiring

One data source, in `ssh_key.tf`:

```hcl
data "azurerm_ssh_public_key" "general" {
  name                = "general-key"
  resource_group_name = azurerm_resource_group.korea_central.name
}
```

Every VM file's `admin_ssh_key.public_key` points at
`data.azurerm_ssh_public_key.general.public_key`.

## Regenerating the key

If the private key needs rotating: generate a new RSA keypair in `keys/`,
then `az sshkey update --name general-key --resource-group
boundary-resource-korea-central --public-key "@keys/general_key.pub"`.
`admin_ssh_key` forces VM replacement on change, so `terraform plan` will
show every VM being destroyed/recreated — review before `apply`.

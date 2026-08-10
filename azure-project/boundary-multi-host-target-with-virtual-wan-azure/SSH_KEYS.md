# SSH keys — shared key setup

All VMs use a single shared key, `general-key`. Keypair lives locally in
`key/` (gitignored via `**/key/` in `azure-project/.gitignore`); the public
half is uploaded to Azure as a `Microsoft.Compute/sshPublicKeys` resource and
looked up from Terraform via a `data` block (out-of-band pattern — Terraform
never manages the private key, so it never regenerates/replaces a key you
hold the private half of).

**Azure requires RSA** for `admin_ssh_key` on `azurerm_linux_virtual_machine`
(ed25519 uploads to `az sshkey` fine, but VM creation rejects it with
`the provided ssh-ed25519 SSH key is not supported`). `general-key` is
RSA 4096-bit.

| Private key         | Public key               | Azure resource | Resource group                |
|----------------------|---------------------------|-----------------|---------------------------------|
| `key/general_key`   | `key/general_key.pub`    | `general-key`  | `boundary-resource-uae-north`  |

This replaces the earlier per-role setup (`self-managed-worker-key`,
`intermediate-worker-key`, `targets-key`, `bastion-key`) — those 4 Azure SSH
key resources still exist but are no longer referenced by any VM; delete
them from Azure directly (`az sshkey delete --name <name> --resource-group
<rg>`) if you want to clean them up, and the corresponding files under
`key/` locally.

## Terraform wiring

One data source, in `ssh_key.tf`:

```hcl
data "azurerm_ssh_public_key" "general" {
  name                = "general-key"
  resource_group_name = azurerm_resource_group.uae_north.name
}
```

Every VM file's `admin_ssh_key.public_key` points at
`data.azurerm_ssh_public_key.general.public_key`.

## Regenerating the key

If the private key needs rotating: generate a new RSA keypair in `key/`,
then `az sshkey update --name general-key --resource-group
boundary-resource-uae-north --public-key "@key/general_key.pub"`.
`admin_ssh_key` forces VM replacement on change, so `terraform plan` will
show every VM being destroyed/recreated — review before `apply`.

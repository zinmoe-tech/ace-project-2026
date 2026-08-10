# SSH keys — per-role setup

Done. Each of the 5 VMs now uses its own role-scoped key instead of the old
shared `intermediate-remote-key`. Keypairs live locally in `keys/` (gitignored
— private key material is never committed); public halves are uploaded to
Azure as `Microsoft.Compute/sshPublicKeys` resources and looked up from
Terraform via `data` blocks (out-of-band pattern — Terraform never manages
the private key, so it never regenerates/replaces a key you hold the private
half of).

**Azure requires RSA** for `admin_ssh_key` on `azurerm_linux_virtual_machine`
(ed25519 uploads to `az sshkey` fine, but VM creation rejects it with
`the provided ssh-ed25519 SSH key is not supported`). All 3 keys below are
RSA 4096-bit.

| Role                 | Private key                      | Public key                            | Azure resource            | Resource group                    |
|----------------------|-----------------------------------|-----------------------------------------|----------------------------|-------------------------------------|
| Self-managed worker  | `keys/self_managed_worker_key`   | `keys/self_managed_worker_key.pub`     | `self-managed-worker-key` | `boundary-self-managed-worker-rg`  |
| Intermediate worker  | `keys/intermediate_worker_key`   | `keys/intermediate_worker_key.pub`     | `intermediate-worker-key` | `boundary-resource-uae-north`      |
| Targets              | `keys/targets_key`               | `keys/targets_key.pub`                 | `targets-key`             | `boundary-resource-central-india`  |

## Terraform wiring

Three data sources in `vm_intermediate_worker-01.tf`:

```hcl
data "azurerm_ssh_public_key" "self_managed_worker" {
  name                = "self-managed-worker-key"
  resource_group_name = azurerm_resource_group.qatar_central.name
}

data "azurerm_ssh_public_key" "intermediate_worker" {
  name                = "intermediate-worker-key"
  resource_group_name = azurerm_resource_group.uae_north.name
}

data "azurerm_ssh_public_key" "targets" {
  name                = "targets-key"
  resource_group_name = azurerm_resource_group.central_india.name
}
```

`admin_ssh_key.public_key` per VM file:

- `vm_self_managed_worker-01.tf`, `vm_self_managed_worker-02.tf` →
  `data.azurerm_ssh_public_key.self_managed_worker.public_key`
- `vm_intermediate_worker-01.tf`, `vm_intermediate_worker-02.tf` →
  `data.azurerm_ssh_public_key.intermediate_worker.public_key`
- `vm_linux_target-01.tf` →
  `data.azurerm_ssh_public_key.targets.public_key`

## Regenerating a key

If a private key needs rotating: generate a new RSA keypair in `keys/`, then
`az sshkey update --name <name> --resource-group <rg> --public-key "@keys/<file>.pub"`.
`admin_ssh_key` forces VM replacement on change, so `terraform plan` will show
the affected VM(s) being destroyed/recreated — review before `apply`.

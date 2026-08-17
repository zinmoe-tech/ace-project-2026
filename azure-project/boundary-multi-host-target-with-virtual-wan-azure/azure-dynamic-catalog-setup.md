# Azure service principals — dynamic host catalogs (vm-03 / vm-04)

Two separate app registrations, one per VM's catalog. Don't reuse one for
both — vm-04's catalog rotates its secret automatically, which would
break vm-03's catalog if they shared an identity. Never paste the
printed `password` (client secret) into chat or into a file — export it
straight into your shell.

## 1. Confirm you're logged into the right subscription

```bash
az account show --query "{name:name, id:id}" -o table
az account show --query id -o tsv

```

Should show subscription id `8d155826-e421-4063-91f2-23ddd65102f1` (the
one `linux-target-rsg` lives in — matches the `azure_subscription_id`
default in `variables.tf`). If not, `az login` and/or
`az account set --subscription 8d155826-e421-4063-91f2-23ddd65102f1`.

## 2. Create the vm-03 service principal (Reader, scoped to linux-target-rsg)

```bash
az ad sp create-for-rbac \
  --name "boundary-linux-target-03-discovery" \
  --role Reader \
  --scopes /subscriptions/8d155826-e421-4063-91f2-23ddd65102f1/resourceGroups/linux-target-rsg
```

Prints JSON like:

```json
{
  "appId": "...",
  "displayName": "boundary-linux-target-03-discovery",
  "password": "...",
  "tenant": "..."
}
```

Export directly from that output (don't write these down anywhere):

```bash
export TF_VAR_azure_tenant_id="<tenant>"
export TF_VAR_azure_sp_vm3_client_id="<appId>"
export TF_VAR_azure_sp_vm3_client_secret="<password>"
```

## 3. Create the vm-04 service principal (same role/scope, different identity)

```bash
az ad sp create-for-rbac \
  --name "boundary-linux-target-04-discovery" \
  --role Reader \
  --scopes /subscriptions/8d155826-e421-4063-91f2-23ddd65102f1/resourceGroups/linux-target-rsg
```

```bash
export TF_VAR_azure_sp_vm4_client_id="<appId>"
export TF_VAR_azure_sp_vm4_client_secret="<password>"
```

(`tenant` will be the same value as step 2 — no need to re-export
`TF_VAR_azure_tenant_id`.)

## Role review

```bash
az role assignment list \
  --assignee <appId> \
  --scope /subscriptions/8d155826-e421-4063-91f2-23ddd65102f1/resourceGroups/linux-target-rsg \
  -o table
```

## 4. Apply

Still needs `TF_VAR_boundary_password` (see `BOUNDARY_TARGET_REGISTRATION.md`).
Once all the `TF_VAR_*` above are exported in the same shell:

```bash
terraform plan \
  -target='boundary_host_catalog_plugin.linux_targets_03_dynamic' \
  -target='boundary_host_set_plugin.linux_targets_03_dynamic' \
  -target='boundary_host_catalog_plugin.linux_targets_04_dynamic' \
  -target='boundary_host_set_plugin.linux_targets_04_dynamic'
```

Review it, then swap `plan` for `apply` (drop the `boundary_target_*_ssh`
resources from the target list too if you want the targets created in
the same pass — they depend on these host sets, so `-target` on the
catalogs/host-sets alone won't create them).

## Cleanup

These app registrations only need Reader on one resource group — safe to
delete once you're done testing:

```bash
az ad sp delete --id <appId>
```

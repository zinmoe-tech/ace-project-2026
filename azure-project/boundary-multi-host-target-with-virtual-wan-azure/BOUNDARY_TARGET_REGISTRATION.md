# Boundary target registration — step by step

Automates what used to be manual `boundary` CLI steps: registering the
linux-target VMs as Boundary hosts/targets happens via `terraform apply`
now, using the official `hashicorp/boundary` provider.

## Steps

1. **Get the project scope ID.** Run this with your own `boundary` CLI
   session authenticated:
   ```bash
   boundary scopes list -recursive -format json | jq '.items[] | select(.type=="project")'
   ```
   Note the `p_...` ID — needed for step 5.

2. **Choose a credential method.** Currently wired for password auth
   (`admin` login + password) against auth method `ampw_sVTvvqApr1`. A
   long-lived token would need `providers.tf` changed instead.

3. **Provider added** — `providers.tf`:
   - `required_providers.boundary` (`hashicorp/boundary ~> 1.1`)
   - `provider "boundary"` block: `addr`, `auth_method_id`,
     `auth_method_login_name`, `auth_method_password = var.boundary_password`
   - Credential never hardcoded — comes from `TF_VAR_boundary_password`.

4. **Registration resources added** — `boundary_linux_target_registration.tf`,
   one catalog/host/host-set/target block per VM:
   - `boundary_host_catalog_static.linux_targets_0N`
   - `boundary_host_static.linux_target_0N` → `172.20.10.{4,5,6,7}` for
     `linux-target-01`..`linux-target-04`
   - `boundary_host_set_static.linux_targets_0N`
   - `boundary_target.linux_target_0N_ssh` (tcp/22), with
     `ingress_worker_filter`/`egress_worker_filter` set to
     `"ingress-worker" in "/tags/type"` / `"egress-worker" in "/tags/type"`
     — matches the tags already live on the real workers.
   - `variables.tf`: `boundary_password` (sensitive), `boundary_project_scope_id`.

5. **`terraform init`** — done, provider plugin installed
   (`hashicorp/boundary v1.6.1`).

6. **Apply, once you have the scope ID and password ready:**
   ```bash
   export TF_VAR_boundary_password="<your password>"
   terraform apply -var="boundary_project_scope_id=<p_...>"
   ```
   Or put `boundary_project_scope_id` in a gitignored `.tfvars` file instead
   of passing it inline every time.

## Adding a future target VM

Same pattern, no manual CLI: add a `boundary_host_static` (new private IP)
+ `boundary_host_set_static` entry, and either add it to the existing
target's `host_source_ids` or create a new `boundary_target` — then
`terraform apply`.

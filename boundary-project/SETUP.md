# Boundary Project — Setup Checklist

Two independent Terraform root modules (no shared state/backend — they find
each other via AWS tags), plus a Packer-built worker AMI and an HCP
Boundary registration step. **Follow the phases in order — later phases
depend on earlier ones actually finishing, not just starting.**

| Module | What it is |
|---|---|
| `self-managed-worker-01/` | VPC `10.1.0.0/16`, bastion (public) + worker (private) EC2 instances |
| `profile-service/` | VPC `192.168.0.0/16`, private target instance `profile-service` |

There's a real chicken-and-egg here, resolved with two count-gated
booleans in `self-managed-worker-01/terraform.tfvars`
(`create_bastion_instance`, `create_worker_instance`): the worker instance
needs the Packer-built AMI to exist, but Packer needs *this module's own
public subnet* to launch its temporary build instance into (this account
has no default VPC). So the network gets created first, with both
instances turned off, then Packer builds using that subnet, then the
instances get turned on.

---

## Phase 0 — Prerequisites

- [ ] Terraform >= 1.5, Packer >= 1.10, AWS CLI, `jq` installed
- [ ] AWS profile `master-access` configured and working:
  ```bash
  aws configure --profile master-access
  aws sts get-caller-identity --profile master-access   # must succeed, not error
  ```
- [ ] Three EC2 key pairs exist in AWS, `.pem` files saved locally:
  - `jump-host-key-pair` (bastion)
  - `self-managed-worker-01` (worker)
  - `profile-key` (profile-service target)
- [ ] HCP Boundary cluster already provisioned (cluster ID is baked into `packer/files/pki-worker.hcl.tmpl`)
- [ ] HCP Packer **registry enabled** for your project — HCP console → your project → **Packer** tab → enable it if prompted. Without this, every build fails with a 404 regardless of anything else being correct.
- [ ] HCP service principal `client_id` / `client_secret` + HCP project ID on hand

---

## Phase 1 — Bootstrap the network only

```bash
cd self-managed-worker-01
terraform init
terraform apply
```

- [ ] Confirm in `terraform.tfvars`: `create_bastion_instance = false`, `create_worker_instance = false`, `enable_profile_peering_route = false`
- [ ] Apply succeeds — creates VPC, subnets, NAT/IGW, security groups. **No EC2 instances yet.**

---

## Phase 2 — Build the worker AMI

Packer launches its temporary build instance into the public subnet Phase 1
just created (found by tag, not a hardcoded ID or default VPC).

```bash
cd packer
./build.sh
```

**✅ Checkpoint — do not skip:**
- [ ] `./build.sh` completed with no errors (watch for `Builds finished but no artifacts were created` — that means it failed, even if some steps printed success)
- [ ] HCP Packer UI → `boundary-self-managed-worker` bucket → your build appears
- [ ] Assigned that build to a channel named `production` (Bucket → iteration → **Assign to channel**)
- [ ] Channel name matches `hcp_packer_channel` in `self-managed-worker-01/terraform.tfvars`

---

## Phase 3 — Apply self-managed-worker-01 again (turn instances on)

```bash
cd ..   # back to self-managed-worker-01/
```

- [ ] Edit `terraform.tfvars`: set `create_bastion_instance = true` and `create_worker_instance = true`

```bash
terraform apply
```

- [ ] Apply succeeds — creates the bastion and the worker (booting from the Phase 2 AMI via the `hcp_packer_artifact` data source)
- [ ] `terraform output bastion_public_ip` — save this for later

---

## Phase 4 — Apply profile-service

```bash
cd ../profile-service
terraform init
terraform apply
```

- [ ] Apply succeeds — creates the `192.168.0.0/16` VPC, target instance, and the VPC peering connection

---

## Phase 5 — Apply self-managed-worker-01 once more (enable the peering route)

Only now does the peering connection from Phase 4 exist for this module to find.

```bash
cd ../self-managed-worker-01
```

- [ ] Edit `terraform.tfvars`: set `enable_profile_peering_route = true`

```bash
terraform apply
```

- [ ] Apply succeeds — adds the route in the worker's private route table toward `profile-service`

---

## Phase 6 — Register the worker with HCP Boundary

The AMI auto-starts `boundary-worker.service` and renders its own config on
boot, but registration approval is a manual, per-instance step.

SSH to the worker via the bastion, then:

```bash
sudo journalctl -flu boundary-worker.service   # confirm it started cleanly
sudo cat /etc/boundary.d/worker/auth_request_token
```

- [ ] HCP Boundary UI → **Workers → New Worker → PKI-based** → paste the token
- [ ] Worker's **Details** tab shows `Last Seen` updating, has an ID (`w_...`)

---

## Phase 7 — Verify target reachability

From the **worker** instance (not the bastion — only the worker's route table got the Phase 5 route):

```bash
scp -i profile-key.pem <file> ubuntu@192.168.10.<x>:/home/ubuntu/
```

- [ ] `profile-key.pem` is present on the worker (scp it up from local first if not)
- [ ] Connection reaches the host (even a publickey rejection confirms the network path works)

---

## Phase 8 — Create the Boundary target

HCP Boundary UI, inside your project:

- [ ] **Host Catalogs → New** (static), e.g. `profile-service-catalog`
- [ ] **Hosts → New** → address = `profile-service`'s private IP
- [ ] **Host Sets → New**, add the host
- [ ] **Targets → New** (type `TCP`, port `22`), attach the host set under **Host Sources**
- [ ] Target's **Workers** tab → set **egress worker filter** so sessions route through your worker specifically:
  ```
  "profile-aws" in "/tags/instance"
  ```

CLI equivalent: `boundary host-catalogs create static`, `boundary hosts
create static`, `boundary host-sets create static`, `boundary targets
create tcp`, `boundary targets update tcp -egress-worker-filter ...`
(needs `BOUNDARY_ADDR` + `BOUNDARY_TOKEN` — see troubleshooting below).

---

## Phase 9 — Connect

```bash
boundary connect ssh -target-id <TARGET_ID> -- -l ubuntu
```

---

## Known issues (already fixed) — root cause and solution

History of real bugs hit while building this out, kept here so the *why*
behind the current structure (count-gated variables, tag-based lookups,
build order) doesn't get lost. If you're just following the checklist
above, you shouldn't hit any of these — they're already fixed in the code.

| # | Issue | Root cause | Solution |
|---|---|---|---|
| 1 | `self-managed-worker-01` and `profile-service` had dangling references (`aws_vpc.this`, `aws_internet_gateway.this`) that errored on `terraform validate` | Copy-pasted between modules without updating resource names to match what was actually declared (`aws_vpc.self-manged-worker-1-vpc`, etc.) | Fixed every reference to point at the real resource name. |
| 2 | `profile-service` had no `variables.tf` / `providers.tf` / `versions.tf` at all | Module scaffolding was incomplete — resources referenced `var.*` that was never declared anywhere in the directory | Added all three files, mirroring `self-managed-worker-01`'s structure. |
| 3 | `self-managed-worker-01`'s peering route (`data.aws_vpc_peering_connection.profile`) failed on every fresh deploy | Circular dependency: this module's data source needed `profile-service`'s peering connection to exist, but `profile-service` needed this module's VPC to exist first — neither could apply first | Gated the data source + route behind `enable_profile_peering_route` (`count`), default `false`. Apply this module, then `profile-service`, then flip the flag and apply again. |
| 4 | `terraform plan` failed: `The provider hashicorp/hcp does not support data source "hcp_packer_image"` | Used a data source name from memory/docs without checking it against the actually-installed provider version (0.112.0) | Queried the real schema with `terraform providers schema -json`, found it was renamed to `hcp_packer_artifact` with different argument/attribute names (`platform` not `cloud_provider`, `external_identifier` not `cloud_image_id`), fixed both. |
| 5 | `./build.sh` failed: `The bucket with identifier boundary-self-managed-worker does not exist` | `terraform apply` was run before the Packer build had ever been run — nothing had published to HCP Packer yet | Established the real dependency order: Packer build must run before any Terraform apply that consumes its image. |
| 6 | `./build.sh` failed: `404 ... No HCP Packer registry was found for this organization and project` | The HCP Packer registry (the parent container for buckets) was never enabled for that HCP project — a one-time manual setup step, not a config bug | Enabled it in the HCP console (project → **Packer** tab). Nothing to fix in code. |
| 7 | `./build.sh` printed a deprecation warning for `hcp_packer_registry` | That block was nested inside `build { }`, which Packer 1.12.1+ deprecated in favor of a template-level block | Moved `hcp_packer_registry` to the top level of `boundary-worker.pkr.hcl`, alongside `packer { }`. |
| 8 | `./build.sh` failed: `NoCredentialProviders: no valid providers in chain` | No AWS credentials existed anywhere on the machine — no profile configured, no env vars | Ran `aws configure --profile master-access`. Also added an explicit `profile` argument to the Packer `amazon-ebs` source so it never silently depends on whatever's default. |
| 9 | `./build.sh` failed: `VPCIdNotSpecified: No default VPC for this user` | This AWS account has no default VPC, and Packer's builder didn't specify one — compounded by the fact that the *intended* VPC (this module's own) didn't exist yet either, since Terraform hadn't been applied | Split `self-managed-worker-01` into a network-only bootstrap apply (both instances `count = 0`) that runs before Packer, then added `vpc_filter`/`subnet_filter` to the Packer source so it finds that subnet by tag once it exists. |
| 10 | `terraform validate` failed on `outputs.tf`: `A managed resource "aws_instance" "bastion" has not been declared` | Manually commented out `aws_instance.bastion` in `ec2.tf` (to work around issue #9) without updating the outputs that referenced it | Replaced manual commenting with the `create_bastion_instance`/`create_worker_instance` `count` gates (see #9) and wrapped the outputs in `try(..., null)` so they're safe regardless of whether the instance exists yet. |

---

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `terraform apply` fails: `The bucket with identifier boundary-self-managed-worker does not exist` | Phase 2 wasn't run, or ran but didn't finish publishing. Run `./build.sh`, confirm it succeeds, **then** apply. |
| `terraform apply` fails: `failed to get Version by Channel Name` | Bucket exists but no build is on the channel named in `hcp_packer_channel`. Assign one in the HCP Packer UI. |
| `./build.sh` fails: `404 ... No HCP Packer registry was found for this organization and project` | The HCP Packer registry itself isn't enabled for that project yet. HCP console → project → **Packer** tab → enable it. Double-check you're in the right project — this error also fires if you're looking at the wrong one. |
| `./build.sh` fails: `no valid credential sources for  found` / `NoCredentialProviders` | No AWS credentials available at all. Run `aws configure --profile master-access`, verify with `aws sts get-caller-identity --profile master-access`. |
| `./build.sh` fails: `VPCIdNotSpecified: No default VPC for this user` | This account has no default VPC and Packer had nowhere to launch its build instance. Fixed by the `vpc_filter`/`subnet_filter` in `boundary-worker.pkr.hcl` — but this only works if Phase 1 (network bootstrap) has already been applied. Run Phase 1 before Phase 2. |
| `scp`: `Permission denied (publickey)` | Network path is fine (peering/routes/security groups all worked) — it's purely an SSH key mismatch. Use `-i` with the right key, and confirm the key file actually exists on the machine you're running `scp` from. |
| `boundary` CLI: `dial tcp 127.0.0.1:9200: connect: connection refused` | `BOUNDARY_ADDR` isn't set — CLI defaulted to a nonexistent local controller. Export it to your HCP cluster URL. |
| `boundary` CLI: `failed to open keyring` | Normal on a headless server. Use `-keyring-type=none` and capture the token from `boundary authenticate ... -format=json` into `BOUNDARY_TOKEN` yourself. |
| Used a worker ID (`w_...`) where a target ID (`ttcp_...`) was expected | Different resource types — `boundary targets list` gives the real target ID. |
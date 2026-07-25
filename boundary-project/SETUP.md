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

To get token from terraform output, use the below command

$terraform output -raw worker_auth_request_token

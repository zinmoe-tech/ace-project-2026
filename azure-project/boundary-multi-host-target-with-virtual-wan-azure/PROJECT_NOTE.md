# Boundary over Virtual WAN — project note

Multi-hop Boundary session brokering across four Azure regions, where the
target subnet can reach exactly three IP addresses and nothing else.

> **No identifiers in this document.** Cluster IDs, scope IDs, tenant and
> subscription IDs, service principal IDs and every secret are referenced as
> placeholders. Real values live in `terraform.tfvars` (gitignored) or in
> `TF_VAR_*` environment variables. Key material lives in `key/` and `keys/`,
> both gitignored.

---

## 1. What this builds

A user with no network access to UAE North opens an SSH session to a VM
there, without ever holding the key, and without that VM being reachable
from the internet or from any other machine in the estate.

Three mechanisms stack to make that true:

- **Boundary multi-hop workers** — a public-facing ingress worker hands off
  to a private egress worker that makes the final connection.
- **Virtual WAN route tables** — the target VNet reads a routing table
  containing three `/32` host routes and nothing else, so it is physically
  incapable of reaching anything but the egress workers.
- **Injected credentials** — the SSH private key lives in Boundary and is
  applied at the egress worker. The user never receives it.

Two registration styles run side by side — hand-written static hosts for
targets 01–02, Azure tag discovery for 03–04 — so the same estate exercises
both models.

---

## 2. Why these technologies

Each choice below solves a specific problem. Recorded here so a future
reader can tell which parts are load-bearing and which are incidental.

### Boundary — instead of VPN + distributed SSH keys

**Problem.** Giving an engineer SSH access to a private VM conventionally
means putting them on a VPN and handing them a private key. The VPN grants
network reach to everything the route table allows, not just the one host
they need. The key, once copied, cannot be un-copied — rotation means
touching every holder, and a leaked key is indistinguishable from a
legitimate one.

**Solution.** Boundary brokers each session individually. The user
authenticates to Boundary, is authorised for one target, and gets a proxied
connection. They never join the network and never hold the key. Revoking
access is a role change, not a key rotation.

**Rejected alternative.** Azure Bastion covers the same ground for a single
VNet, but it terminates in the VNet it is deployed to, has no concept of
cross-region worker chaining, and does not solve credential injection.

### Multi-hop workers — instead of one worker tier

**Problem.** The target VNet must accept no inbound connection from the
internet. But HCP Boundary's control plane runs outside Azure and cannot
reach a private VNet, so something inside has to bridge the two — and if
that something listens for inbound connections, the private network has an
open door again.

**Solution.** Two worker tiers. The **self-managed workers** hold public IPs
and accept client connections on 9202. The **intermediate workers** are
private, listen to nobody, and dial *outbound* to the self-managed tier,
holding a reverse tunnel open. Traffic reaches the private network over a
connection that the private side initiated.

This is why `intermediate-worker-0N-nsg` has no 9202 inbound rule at all —
not an oversight, the entire point.

### Virtual WAN — instead of VNet peering

**Problem.** Four VNets in four regions. Full-mesh peering needs
`n(n−1)/2` = six links, each configured twice, and grows quadratically.
Worse, peering gives no per-spoke routing policy: a peered VNet either sees
its neighbour or it does not, and there is no place to express "these three
may talk to each other, that fourth may only reach three specific hosts".

**Solution.** A managed transit hub where every VNet connects once, and
routing policy lives in **route tables** rather than in the links.
Different connections can read different tables — which is the mechanism the
whole isolation model depends on.

**Rejected alternative.** Hub-and-spoke with a network virtual appliance
gives the same control, but means running, patching, and paying for a
firewall VM. Virtual WAN's route tables were sufficient without one.

### Two route tables and `/32` routes — instead of NSGs alone

**Problem.** NSGs are attached per-NIC and are trivially edited on a single
VM. A single wrong rule on one target would silently open a path from the
self-managed workers or the bastion. Relying on NSGs alone means the
isolation is exactly as strong as the least carefully reviewed VM.

**Solution.** Enforce it a second time at the routing layer, where an
individual VM cannot influence it. `linux-target-rtb` contains three `/32`
routes and nothing else, so even a wide-open NSG on a target leaves the
packet with nowhere to go.

`/32` rather than `/24` matters because the intermediate workers share a
subnet with the self-managed workers and the bastion. Propagation cannot
express that distinction — it advertises a VNet's whole address space — so
host-granular reachability is only achievable with hand-written static
routes. That is why this one table is static while the other is entirely
propagated.

### Injected credentials — instead of brokered ones

**Problem.** Even with Boundary in the path, handing the user the key at
session start puts the secret on their machine.

**Solution.** `injected_application_credential_source_ids` applies the key
at the egress worker. The user's SSH client authenticates to Boundary, not
to the host. The key never leaves the control plane and the worker.

This requires the target to be type `ssh` rather than `tcp` — a `tcp`
target cannot inject, only broker.

### Terraform across both providers — instead of clicking

**Problem.** This estate spans two systems that must agree: an Azure NIC
holds an address, and a Boundary host record points at that same address.
Built by hand, the two drift the moment anything is rebuilt, and the failure
surfaces as a session timeout with no obvious cause.

**Solution.** One `terraform apply` covering `azurerm` and `boundary`
together, with the Boundary host reading
`azurerm_network_interface.…private_ip_address` directly rather than a typed
copy. The two cannot disagree.

### Static *and* dynamic catalogs — because neither alone is right

**Problem.** Hand-written host addresses go stale silently. Full tag-based
discovery fixes that but, with one broad filter, produces a single target
that lands on any matching machine — losing per-machine access control.

**Solution.** Run both, chosen per target, and use a *unique tag value per
VM* on the dynamic side so discovery keeps addresses fresh without
collapsing four machines into one target. Section 8 covers the trade-off in
full.

### Bastion — because the workers deliberately cannot reach anything

**Problem.** Both worker classes end with `deny-all-other-outbound`. That is
correct for their role, and it also means no package updates, no
troubleshooting from the box itself, and no easy way in.

**Solution.** One jump box in Southeast Asia with open TCP egress, used for
administration only. It is deliberately excluded from `linux-target-rtb`, so
having it changes nothing about what can reach the targets.

---

## 3. The path of one session

```
                    ┌──────────────────────────────┐
                    │  HCP Boundary control plane  │
                    └──────────────────────────────┘
                        ▲                    ▲
                        │ session auth       │ worker registration
                        │                    │
  ┌────────┐      ┌─────────────┐      ┌──────────────┐      ┌───────────────┐
  │ client │─────▶│ self-managed │─────▶│ intermediate │─────▶│ linux-target  │
  │        │ TLS  │   worker     │ rev. │   worker     │ SSH  │ 172.20.10.x   │
  └────────┘ 9202 │ public IP    │tunnel│ private only │  22  └───────────────┘
                  │   INGRESS    │      │    EGRESS    │
                  └─────────────┘      └──────────────┘
                                              │              │
                                              └──── hub ─────┘
                                       linux-target-rtb: 3 × /32 only
```

The direction of the second hop matters: **intermediate workers never listen
on 9202.** They dial out to all three self-managed workers and hold the
connection open, which is why their NSGs have no 9202 inbound rule.

The target VM has no public IP, no Boundary software, and no route to
anything except the three egress workers.

---

## 4. Network

### Address plan

| Resource group | Region | VNet | Address space | Subnet | Holds |
|---|---|---|---|---|---|
| `boundary-resource-southeast-asia` | Southeast Asia | `boundary-self-managed-vn` | `10.1.0.0/16` | `10.1.100.0/24` | worker pair + bastion |
| `boundary-resource-korea-central` | Korea Central | `boundary-korea-central-vn` | `10.2.0.0/16` | `10.2.100.0/24` | worker pair |
| `boundary-resource-japan-east` | Japan East | `boundary-japan-east-vn` | `10.3.0.0/16` | `10.3.100.0/24` | worker pair |
| `linux-target-rsg` | UAE North | `linux-target-vn` | `172.20.0.0/16` | `172.20.10.0/24` | 4 targets |
| `virtual-wan-rsg` | Korea Central | — (hub) | `10.0.99.0/24` | — | WAN + hub + 2 route tables |

### Association vs propagation

Every hub connection has two independent settings:

| Setting | Meaning | Count |
|---|---|---|
| `associated_route_table_id` | which table **my packets** are looked up in | exactly one |
| `propagated_route_table` | which tables **my prefixes** are written into | any number |

Different things travel each arrow — packets one way, prefixes the other.
That asymmetry is what produces one-way reachability.

```
to-southeast-asia-vn ──associate──┐
to-korea-central-vn  ──associate──┼──▶ global-v-net-connection-rtb
to-japan-east-vn     ──associate──┘         10.1.0.0/16
                     ··propagate··▶         10.2.0.0/16
                                            10.3.0.0/16
                                            172.20.0.0/16  ◀··┐
                                     (all learned by propagation)
                                                              │
to-linux-target-vn   ──associate──▶ linux-target-rtb          │
                                       10.1.100.5/32          │
                                       10.2.100.5/32          │
                                       10.3.100.5/32          │
                                     (hand-written /32s)      │
                     ··propagate·································┘
                       the only reason a worker can reach the targets
```

**Absent from `linux-target-rtb`:** `10.1.0.0/16`, `10.2.0.0/16`,
`10.3.0.0/16`. Self-managed workers and the bastion are therefore
unreachable from any target, even though they share a `/24` with the
intermediate workers. `/32` means that one host.

Two consequences worth remembering:

- **Routing is evaluated per direction, not per session.** A self-managed
  worker can send a packet to a target — the workers' table has
  `172.20.0.0/16` — but the reply is looked up in `linux-target-rtb`, finds
  no route back, and dies in the hub. Isolation is enforced on the return
  path.
- **`global-v-net-connection-rtb` has no static routes deliberately.** A
  route in it would need `next_hop` pointing at a connection that already
  associates with it, which Terraform rejects as a dependency cycle.
  Propagation fills it anyway.

Propagation has no granularity knob — it advertises a VNet's whole address
space. Host-level precision is only achievable with static routes, which is
why `linux-target-rtb` has three hand-written entries and no propagation
sources.

---

## 5. Inventory

All Ubuntu 24.04 LTS, admin `azureuser`, password auth disabled.

| VM | Region | Private IP | SKU | Priority | Role |
|---|---|---|---|---|---|
| `self-managed-worker-01` | Southeast Asia | `10.1.100.4` | `Standard_DC1s_v3` | on-demand | ingress |
| `intermediate-worker-01` | Southeast Asia | `10.1.100.5` | `Standard_DC2s_v3` | on-demand | egress |
| `bastion-southeast-asia` | Southeast Asia | `10.1.100.6` | `Standard_DC1s_v3` | on-demand | jump box |
| `self-managed-worker-02` | Korea Central | `10.2.100.4` | `Standard_D2s_v5` | on-demand | ingress |
| `intermediate-worker-02` | Korea Central | `10.2.100.5` | `Standard_D2s_v5` | on-demand | egress |
| `self-managed-worker-03` | Japan East | `10.3.100.4` | `Standard_D2as_v6` | on-demand | ingress |
| `intermediate-worker-03` | Japan East | `10.3.100.5` | `Standard_D2as_v6` | on-demand | egress |
| `linux-target-01` | UAE North | `172.20.10.4` | `Standard_F1als_v7` | Spot | target · static |
| `linux-target-02` | UAE North | `172.20.10.5` | `Standard_F1als_v7` | Spot | target · static |
| `linux-target-03` | UAE North | `172.20.10.6` | `Standard_F1als_v7` | Spot | target · dynamic |
| `linux-target-04` | UAE North | `172.20.10.7` | `Standard_F1als_v7` | regular | target · dynamic |

Every SKU choice is a quota workaround and the reasoning sits in each VM
file's comment — B-series restricted in UAE North, only zone 2 with capacity
for `DC2s_v3` in Southeast Asia, UAE North's LowPriority quota fully consumed
by targets 01–03 which is why target-04 runs at regular priority. Read those
before changing a size.

---

## 6. Security posture

| NSG | Inbound | Outbound | Catch-all |
|---|---|---|---|
| `self-managed-worker-0N` | 22 from `*`; 9202 from `*` (clients dial directly); ICMP | any port → 3 HCP proxy IPs; ICMP | deny all @ 4096 |
| `intermediate-worker-0N` | 22 (scope differs per worker); ICMP; **no 9202** | 9202 → the three self-managed workers; 22 → `172.20.10.0/24`; ICMP | deny all @ 4096 |
| `linux-target-0N` | 22 from `10.1.100.5`, `10.2.100.5`, `10.3.100.5`; ICMP | ICMP only explicitly | none — Azure defaults apply |
| `bastion-southeast-asia` | 22 from `*`; ICMP | all TCP; ICMP | open egress |

The target NSG allow-list is the **same three addresses as the route table**.
The isolation is stated twice, in two independent layers — add a fourth
egress worker and both need editing, or SSH fails with no indication which
layer dropped it.

Note the asymmetry in the catch-all column: workers end with an explicit
deny-all outbound, targets do not. Targets keep Azure's default outbound
rules. With no public IP and no NAT gateway this is not an exposure today,
but it is an inconsistency rather than a decision.

Neither worker class can reach `management.azure.com`. Setting a **worker
filter on the plugin host catalog** would therefore break discovery — leave
that field empty so the control plane performs it.

---

## 7. Boundary layer

| | |
|---|---|
| Cluster | `https://<hcp-cluster-id>.boundary.hashicorp.cloud` |
| Auth method | `<auth-method-id>` (password) |
| Org / project | `<org>` / `<project>` |
| Project scope | `<project-scope-id>` |
| Provider | `hashicorp/boundary ~> 1.1` |

Worker configuration (see `intermediate-boundary-config.md`):

```hcl
listener "tcp" { address = "0.0.0.0:9202"  purpose = "proxy" }

worker {
  public_addr       = "<this worker's private IP>"
  auth_storage_path = "/etc/boundary.d/worker"
  initial_upstreams = [ "10.1.100.4:9202", "10.2.100.4:9202", "10.3.100.4:9202" ]
  tags { type = [ ... ] }
}
```

All four targets share one credential — `linux-targets-cred-store` holding
an SSH private key credential for `azureuser`, read from `key/linux_key`.
Targets are type `ssh`, `default_port = 22`,
`session_connection_limit = -1`, with both worker filters set.

---

## 8. Host registration

Registering a machine with Boundary is **metadata, not installation**.
Nothing runs on a target VM — it is a plain Ubuntu box with `sshd` and a
public key, identical to one nobody brokers access to.

### The chain

```
host catalog  ──▶  host  ──▶  host set  ──▶  target
"where do        "where     "who is in     "how do I
 definitions      is the     this group?"   connect?"
 come from?"      machine?"
```

| Layer | Holds | Links via |
|---|---|---|
| host catalog | scope; plugin credentials if dynamic | — |
| host | an address — no port, no protocol | `host_catalog_id` |
| host set | a list, or a query | `host_ids` / `filter` |
| target | port, protocol, credentials, worker filters | `host_source_ids` |

**A target accepts host *sets*, never hosts.** The argument is
`host_source_ids`, and a host ID will not be accepted there.

### Static vs dynamic

| | Static — targets 01, 02 | Dynamic — targets 03, 04 |
|---|---|---|
| Resource | `boundary_host_catalog_static` | `boundary_host_catalog_plugin` (azure) |
| Catalog holds | nothing but a scope | tenant, subscription, client ID + secret |
| Host records | you write the IP by hand | Boundary creates them from the Azure API |
| Set membership | `host_ids = [hst_…]` | `filter = "tagName eq … and tagValue eq …"` |
| Re-evaluated | only on `terraform apply` | on a background sync interval |
| IP change | silently stale until you edit | picked up automatically |
| VM deleted | host record lingers | host drops out of the set |
| Onboarding action | edit `.tf`, apply | tag the VM in Azure |
| Still needs per VM | host + set + target | set + target |
| Extra dependency | none | service principal with Reader |

**Neither model health-checks anything.** A host set answers "who is in this
group", not "is this host reachable". A dynamic set verifies only that the
VM still exists carrying the tag — a stopped VM stays in the set. Liveness
is discovered when the egress worker opens the TCP connection, not before.

### The trade-off chosen here

Both dynamic sets filter on a **unique tag value per VM**. Discovery does
real work — addresses stay current, nothing is hand-typed — but onboarding a
fifth machine still needs a new host set and a new target in Terraform. The
alternative is one shared tag value, one set, one target: genuine zero-touch
growth, at the cost of a single target that lands on any tagged machine.

**Precision per machine, or zero-touch growth. Not both.**
`fleet-auto-register.sh` splits the difference — it creates a dedicated
target per discovered host, because Boundary syncs hosts automatically but
never creates targets on its own.

---

## 9. Load balancing and failover

Boundary distributes load in two places. This project uses one.

| Mechanism | How it picks | Used here |
|---|---|---|
| host selection within a host set | one host per session from the set's members — no weighting, no health check, no retry onto a second host | **unused** — every set holds one host |
| worker selection within a filter match | sessions spread across every worker whose tags satisfy the filter | **active** — 3 ingress and 3 egress workers match |

The real distribution is **across workers, not across targets**. Both worker
filters match a *class* rather than a name, which is what makes all three
eligible for every session. Pinning a filter to one worker's name would
silently convert this into a single point of failure.

### The upstream mesh

```
 self-managed-worker-01 ◀─┐ ┌─▶ intermediate-worker-01 ──┐
 self-managed-worker-02 ◀─┼─┼─▶ intermediate-worker-02 ──┼─▶ linux-target 01–04
 self-managed-worker-03 ◀─┘ └─▶ intermediate-worker-03 ──┘

 9 outbound tunnels — every intermediate dials all three self-managed
 workers via initial_upstreams, and none of them ever listens on 9202.
```

Egress failover works **only** because all three intermediate workers appear
in `linux-target-rtb` as `/32` routes *and* in every target NSG's
`source_address_prefixes`. Had either list named one worker, Boundary would
still select among three and two thirds of sessions would fail at the last
hop with a timeout — an intermittent fault that reads as flapping rather
than as misconfiguration.

### Blast radius

| Failure | Effect | Recovery |
|---|---|---|
| 1 self-managed worker down | none — clients use another; intermediates keep 2 upstreams | automatic |
| 2 self-managed workers down | none functionally; all load on the survivor | automatic |
| all 3 self-managed down | total outage — no ingress path exists | manual |
| 1–2 intermediate workers down | none — egress selection picks a survivor | automatic |
| all 3 intermediate down | every target unreachable although hub and NSGs are fine | manual |
| 1 target VM down or evicted | that target only; its host record stays in the set | no failover — 1 host per set |
| Virtual WAN hub degraded | all cross-region traffic; only same-VNet hops survive | single hub |
| SSH credential invalid | all four targets at once | one shared credential |
| Discovery SP secret expired | targets 03–04 lose hosts; 01–02 unaffected | rotation disabled |

### Not redundant

- **The hub.** One hub carries every cross-region hop.
- **The targets.** One host per set means no failover by construction —
  correct, since these are distinct machines rather than replicas.
- **The credential.** One SSH key for all four targets. A second
  `boundary_credential_ssh_private_key` in the same store, wired to a
  subset, would contain the blast radius.
- **Spot capacity.** Targets 01–03 can be evicted at any time, and an
  eviction presents as a connect timeout — the same symptom as a routing
  fault.

If a target ever needs real failover the mechanism already exists and is
unused: put two interchangeable hosts in one set. Bear in mind Boundary
picks blind — a dead host in the set is still a candidate.

---

## 10. File map

| File | Contains |
|---|---|
| `providers.tf` | azurerm ~> 3.0, boundary ~> 1.1, HCP address + auth method |
| `variables.tf` | Boundary password, project scope, Azure tenant/subscription/SP vars |
| `resource_groups.tf` | all five resource groups |
| `network_*.tf` | four VNets + subnets, one file per region |
| `vwan.tf` | WAN, hub, both route tables, all four connections |
| `ssh_key.tf` | two `data` lookups — Terraform never manages key material |
| `vm_self_managed_worker-0N.tf` | ingress workers + NSGs |
| `vm_intermediate_worker-0N.tf` | egress workers + NSGs |
| `vm_linux_target-0N.tf` | targets + NSGs; 03/04 carry the discovery tag |
| `vm_bastion_southeast_asia.tf` | jump box |
| `boundary_credentials.tf` | credential store + SSH key credential |
| `boundary_linux_target_static_registration.tf` | catalog/host/set/target for 01–02 |
| `boundary_linux_target_dynamic_registration.tf` | plugin catalog, two filtered sets, two targets |
| `fleet-auto-register.sh` | creates a dedicated target per discovered host |
| `SSH_KEYS.md` | shared-key rationale, RSA requirement, rotation |
| `azure-dynamic-catalog-setup.md` | service principal creation runbook |
| `intermediate-boundary-config.md` | worker HCL + systemd unit |
| `BOUNDARY_TARGET_REGISTRATION.md` | original registration walkthrough |
| `Note.md` | branch-to-branch clarification |

`keys/`, `key/`, `*.tfvars`, `terraform.tfstate*` and `.terraform/` are
gitignored. No key material or secret is tracked.

---

## 11. Runbook

### Apply

```bash
export TF_VAR_boundary_password="…"   # never in a file
# azure_sp_* and boundary_project_scope_id come from terraform.tfvars (gitignored)
terraform init
terraform plan
```

### Add a target — static

Three resources in `boundary_linux_target_static_registration.tf`, then apply:

```
boundary_host_static      → address = new private IP
boundary_host_set_static  → host_ids = [that host]
boundary_target           → host_source_ids = [that set]
                            + injected credential + both worker filters
```

### Add a target — dynamic

1. Tag the VM `boundary_dynamic_target = "linux-target-0N"` — on the VM
   resource, in `linux-target-rsg`.
2. Add a `boundary_host_set_plugin` with
   `filter = "tagName eq 'boundary_dynamic_target' and tagValue eq 'linux-target-0N'"`.
3. Add a `boundary_target` pointing at that set.
4. Wait one sync interval. Hosts never appear instantly.

### Both ways also require

- The VM in `linux-target-vn` / `172.20.10.0/24` — any other VNet has no hub
  connection and is unreachable.
- An NSG allowing 22 inbound from the three intermediate worker IPs.
- The `linux-key` public half in `authorized_keys` for `azureuser`.
- A role granting `authorize-session` on the new target — registration alone
  grants nobody access.

### Triage: a target won't connect

| Symptom | Check | Usual cause |
|---|---|---|
| Host set empty | SP role assignments; tag spelling and case | SP has no Reader, or VM outside `linux-target-rsg` |
| Session times out | `nc -vz <ip> 22` from an intermediate worker | wrong VNet, missing NSG rule, or VM deallocated |
| `Permission denied (publickey)` | `authorized_keys` on the VM | VM built with a different key than `linux-key` |
| No workers available | `boundary workers list -format json` | worker filter matches no worker tag |
| Worker log: dial timeouts | `ping` the upstream; VM power state | upstream deallocated or hub not converged |
| Filter rejected in the GUI | which box you are in | Azure tag syntax pasted into the Boundary worker-filter box |

**Two boxes, two languages.** The catalog's *Worker Filter* speaks Boundary
(`"x" in "/tags/y"`); the host set's *Filter* speaks Azure
(`tagName eq 'x' and tagValue eq 'y'`). Both are labelled "filter", which is
most of why they get confused.

---

## 12. Design notes

The idea worth carrying forward is the separation of **association** from
**propagation**. Most access designs enforce reachability in one layer and
hope; this one splits "what can I see" from "who can see me" and gets a
genuinely one-way relationship out of two settings that look symmetrical.
The NSG allow-lists then restate the same three addresses at the port level,
so the isolation survives a mistake in either layer alone.

The second is that redundancy has to be spelled out in **every layer that
touches the path**. Three egress workers only provide failover because all
three appear in the route table, in every target NSG, and in a worker filter
written against a class rather than a name. Any one of those narrowed to a
single worker would leave the other two selectable but unusable.

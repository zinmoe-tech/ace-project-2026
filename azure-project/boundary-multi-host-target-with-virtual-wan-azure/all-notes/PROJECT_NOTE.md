# Boundary over Virtual WAN — project note

Multi-hop Boundary session brokering across four Azure regions, where the
target subnet can reach exactly three IP addresses and nothing else.

**Architecture diagram:**
<https://app.excalidraw.com/l/9zPQ6SMkB6W/8o3l0R6PbJS>

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

## 2. Why these four decisions

Four choices carry this design. Each is stated as the problem it solves, the
solution adopted, and why the obvious alternative was not enough.

### 2.1 Host catalog — instead of an address on the target

**Problem.** A Boundary target can carry an `address` field directly, which
is the shortest path to a working session:

```hcl
resource "boundary_target" "quick" {
  address      = "172.20.10.4"
  default_port = 22
}
```

It works, and it is a dead end. That address is typed by hand, so it drifts
the moment the VM is rebuilt with a different IP. It belongs to one target,
so nothing else can reuse it. It cannot be discovered, cannot be grouped
with other machines, and cannot be updated from a single place. A target
with a direct address also cannot use host sources at all — the two are
mutually exclusive.

**Solution.** Route every target through the catalog chain, so that *where a
machine is* and *how to connect to it* are stored separately:

```
host catalog  ──▶  host  ──▶  host set  ──▶  target
"where do        "where     "who is in     "how do I
 definitions      is the     this group?"   connect?"
 come from?"      machine?"
```

The payoff is that each layer can change without touching the others. A
machine's IP changes — only the host record moves. Access policy changes —
only the target changes. A whole class of machines needs discovering rather
than listing — only the catalog changes. None of that is expressible when
the address is a literal on the target.

**Why it matters here specifically.** The host record reads
`azurerm_network_interface.…private_ip_address` directly from the Azure
resource, so the Boundary host and the Azure NIC cannot disagree. A typed
address would drift silently and surface later as a session timeout with no
obvious cause.

### 2.2 Virtual WAN — instead of VNet peering

**Problem.** Four VNets across four regions. Full-mesh peering needs
`n(n−1)/2` = six links, each configured from both ends, and the count grows
quadratically with every VNet added. Worse, peering carries no routing
policy: a peered VNet either sees its neighbour or it does not. There is
nowhere to express *"these three may talk to each other freely, that fourth
may reach three specific hosts and nothing else."*

**Solution.** A managed transit hub where every VNet connects once and
routing policy lives in **route tables** rather than in the links. Because
each connection independently chooses which table it reads and which tables
it advertises into, different spokes can be given genuinely different views
of the same network.

That is the mechanism the entire isolation model rests on:

- the three worker VNets read `global-v-net-connection-rtb` and see everything
- the target VNet reads `linux-target-rtb` and sees three `/32` host routes
- the target VNet still *advertises into* the workers' table, so workers can
  reach it

One-way reachability, out of two settings that look symmetrical. Peering
cannot express it at all.

**Why not the alternatives.** Hub-and-spoke with a network virtual appliance
would give the same control, but means running, patching and paying for a
firewall VM. Azure Route Server plus custom UDRs would also work, but puts
the policy in per-subnet route tables that a subnet owner can edit. Virtual
WAN keeps it in the hub, where an individual VM has no influence over it.

### 2.3 Three self-managed workers — instead of one

**Problem.** The self-managed workers are the only publicly reachable part
of this system: clients dial them on 9202 directly. A single one would mean
every session in every region funnels through one VM in one Azure region —
one reboot, one eviction, or one regional incident takes all access away,
and a user far from that region pays the latency on every packet.

There is a second, less obvious failure: the intermediate workers connect
*upstream* to this tier. With one self-managed worker, losing it does not
just block new sessions — it disconnects every intermediate worker from the
control plane at once.

**Solution.** Three, one per region, all carrying the same ingress tag so a
single filter matches all of them:

```
ingress_worker_filter = "\"ingress-worker\" in \"/tags/type\""
```

Boundary spreads sessions across every worker that satisfies the filter, so
this gives distribution and redundancy from the same configuration. Any two
can be down and access still works.

Each intermediate worker then lists **all three** as upstreams, so it stays
registered while any one survives:

```hcl
initial_upstreams = [ "10.1.100.4:9202", "10.2.100.4:9202", "10.3.100.4:9202" ]
```

**The part that is easy to get wrong.** This only works because the filter
matches a *class* rather than a name. Writing `"/name" == "self-managed-worker-01"`
would leave the other two running, healthy, and never selected — a single
point of failure disguised as a three-node tier.

### 2.4 Intermediate workers — instead of connecting to targets directly

**Problem.** The target VNet must accept no inbound connection from the
internet. But HCP Boundary's control plane runs outside Azure and cannot
reach a private VNet, so something inside the network has to bridge the two.
If that something *listens* for inbound connections, the private network has
an open door again — and the self-managed workers cannot do the job either,
because they are the publicly exposed tier, and giving them a route into the
target subnet would put a path from the internet one hop away from the
targets.

**Solution.** A second worker tier that is private, listens to nobody, and
dials **outbound** to the self-managed workers, holding a reverse tunnel
open. Session traffic then reaches the private network over a connection the
private side initiated.

```
client ──▶ self-managed worker ◀── intermediate worker ──▶ target
           public, listens 9202     private, dials out       :22
                                    NEVER listens
```

This is why `intermediate-worker-0N-nsg` has **no 9202 inbound rule at all**
— not an oversight, the entire point of the tier.

**What it buys beyond reachability.** Because the intermediate workers are
the only machines that ever touch the targets, the target's exposure can be
written as a list of exactly three addresses — in the hub route table *and*
in the target NSG. Both lists name the same three IPs. Without a separate
egress tier there would be no such short list to write: the targets would
have to accept connections from whatever machine happened to be brokering,
and the isolation model would have nothing precise to point at.

They are also where credentials land. `injected_application_credential_source_ids`
applies the SSH key at the egress worker, so the key stays inside the
private network and the user never receives it.

---

## 3. The path of one session

Full architecture drawing:
<https://app.excalidraw.com/l/9zPQ6SMkB6W/8o3l0R6PbJS>

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

### The two catalog types

A host catalog answers exactly one question: **who maintains the list of
hosts?** That is the whole difference between the two types. Everything
below the catalog — hosts, sets, targets — keeps the same shape either way.

#### Static catalog — you maintain the list

The catalog itself holds nothing but a scope. Hosts are resources you write,
and a set names them explicitly.

```hcl
resource "boundary_host_catalog_static" "static_host_catalog" {
  scope_id = var.boundary_project_scope_id
}

resource "boundary_host_static" "linux_target_01" {
  host_catalog_id = boundary_host_catalog_static.static_host_catalog.id
  address         = azurerm_network_interface.linux_target_01.private_ip_address
}

resource "boundary_host_set_static" "linux_targets_01" {
  host_catalog_id = boundary_host_catalog_static.static_host_catalog.id
  host_ids        = [boundary_host_static.linux_target_01.id]
}
```

Membership is a literal list. Nothing re-evaluates it until the next
`terraform apply`.

#### Dynamic (plugin) catalog — Azure maintains the list

The catalog holds the credentials needed to query Azure. There are **no
host resources at all** — `boundary_host_set_plugin` has no `host_ids`
argument, and will not accept one. The set carries a *filter*, and Boundary
creates, updates and removes host records itself.

```hcl
resource "boundary_host_catalog_plugin" "dynamic-host-catalog" {
  scope_id    = var.boundary_project_scope_id
  plugin_name = "azure"

  attributes_json = jsonencode({
    disable_credential_rotation = true
    tenant_id                   = var.azure_tenant_id
    subscription_id             = var.azure_subscription_id
    client_id                   = var.azure_sp_client_id
  })
  secrets_json = jsonencode({ secret_value = var.azure_sp_client_secret })
}

resource "boundary_host_set_plugin" "linux_target_03_host_set" {
  host_catalog_id = boundary_host_catalog_plugin.dynamic-host-catalog.id

  attributes_json = jsonencode({
    filter = "tagName eq 'boundary_dynamic_target' and tagValue eq 'linux-target-03'"
  })
}
```

Registration has moved out of Terraform's Boundary resources and into the
**Azure tag** on the VM:

```hcl
tags = { boundary_dynamic_target = "linux-target-04" }
```

Tag a VM and it appears in the set. Remove the tag, or the VM, and it drops
out. Boundary is never told directly.

#### Side by side

| | Static — targets 01, 02 | Dynamic — targets 03, 04 |
|---|---|---|
| Resource | `boundary_host_catalog_static` | `boundary_host_catalog_plugin` (azure) |
| Catalog holds | nothing but a scope | tenant, subscription, client ID + secret |
| Host records | you write them | Boundary creates them from the Azure API |
| Set membership | `host_ids = [hst_…]` | `filter = "tagName eq … and tagValue eq …"` |
| Re-evaluated | only on `terraform apply` | on a background sync interval |
| IP change | silently stale until you edit | picked up automatically |
| VM deleted | host record lingers | host drops out of the set |
| Onboarding action | edit `.tf`, apply | tag the VM in Azure |
| Still needs per VM | host + set + target | set + target |
| Extra dependency | none | service principal with Reader |
| Fails when | an address was mistyped | the SP lacks a role assignment |

#### Choosing between them

Use a **static** catalog when the machine is long-lived with a fixed
address, when there is no cloud API to query (on-prem, another provider,
appliances), or when you want the host list to be reviewable in a pull
request rather than derived at runtime.

Use a **dynamic** catalog when machines are created and destroyed regularly,
when addresses are assigned rather than chosen, or when the set of machines
is defined by a property — a tag, a subscription, a resource group — rather
than by a list someone maintains.

This project uses both so the same estate exercises each: 01–02 are fixed
lab machines, 03–04 stand in for a fleet.

#### Two things neither model does

**Neither health-checks anything.** A host set answers "who is in this
group", not "is this host reachable". A dynamic set verifies only that the
VM still exists carrying the tag — a stopped VM stays in the set. Liveness
is discovered when the egress worker opens the TCP connection, not before.

**Neither creates targets.** This is the ceiling on automation and is
covered next.

### The trade-off chosen here

Both dynamic sets filter on a **unique tag value per VM**. Discovery does
real work — addresses stay current, nothing is hand-typed — but onboarding a
fifth machine still needs a new host set and a new target in Terraform. The
alternative is one shared tag value, one set, one target: genuine zero-touch
growth, at the cost of a single target that lands on any tagged machine.

**Precision per machine, or zero-touch growth. Not both.**

The gap between them is worth naming: Boundary's dynamic catalogs sync
**hosts** into a host set automatically, but they never create **targets**.
A target encodes session policy — worker filters, injected credentials,
connection limits — and nothing in the plugin model turns "a host appeared"
into "create a target for it". Fully automatic onboarding therefore needs
either a broad shared host set feeding one pre-existing target, or an
external step that creates the per-VM target.

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

Terraform lives at the project root; every document lives in `all-notes/`.

### Terraform

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

### Documents — `all-notes/`

| File | Contains |
|---|---|
| `PROJECT_NOTE.md` | this document |
| `SSH_KEYS.md` | shared-key rationale, RSA requirement, rotation |
| `azure-dynamic-catalog-setup.md` | service principal creation runbook |
| `intermediate-boundary-config.md` | worker HCL + systemd unit |
| `BOUNDARY_TARGET_REGISTRATION.md` | original registration walkthrough |

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

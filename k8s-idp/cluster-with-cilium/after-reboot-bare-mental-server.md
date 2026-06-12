# Recovering `idp-cluster` after a reboot / Docker restart

This kind cluster (Cilium CNI, `kubeProxyReplacement=true`) does **not** survive a
host reboot or Docker restart cleanly. When the node containers restart they can get
**new IPs**, which breaks two things:

1. **Cilium** can't reach the API server (it has the *old* control-plane IP baked in) →
   `cilium` agents stuck `Init:0/6`, `cilium-operator` crash-looping → nodes `NotReady`.
2. **Pods** that were running before the restart get stranded in `Unknown` status
   (e.g. everything in `argocd/` and `gatekeeper-system/`).

Work through the steps in order. `kubectl` itself keeps working (it talks to the
API server directly via the kubeconfig), so you can run these even while the cluster
is unhealthy.

---
### To work cilium properlly, demonset (ds) and deployment in ns(kube-system) need to run well.

>> DS name - cilium (ds/cilium)
>> Deployment name - cilium-operator (deploy/cilium-operator)

## Step 0 — Make sure kubectl points at the cluster

```bash
kubectl config use-context kind-idp-cluster
kubectl config set-context --current --namespace=argocd   # so argocd core-mode CLI works
kubectl get nodes
```

If you see `context was not found`, the cluster context name may differ — list them with
`kubectl config get-contexts` and use the `idp-cluster` one.

---

## Step 1 — Check what's broken

```bash
# node health (NotReady => Cilium is down)
kubectl get nodes

# Cilium status (Init:0/6 or CrashLoop => stale IP problem)
kubectl get pods -n kube-system | grep -E 'cilium'

# stranded pods elsewhere
kubectl get pods -A | grep -ivE 'Running|Completed'

# are the kind node containers up? (note: "Up X minutes" = they just restarted)
docker ps --filter "name=idp-cluster" --format '{{.Names}}\t{{.Status}}'
```

---

## Step 2 — Fix Cilium (the stale control-plane IP)  ← the main one

**Why:** Cilium was installed with `k8sServiceHost=<control-plane IP>`. After a restart
the control-plane IP changes, so Cilium dials the old IP and gets `connection refused`
(check with `kubectl -n kube-system logs <cilium-pod> -c config`).

The snippet below **auto-detects** the current IP and re-points Cilium at it:

```bash
# 1. get the CURRENT control-plane internal IP
CP_IP=$(kubectl get node idp-cluster-control-plane \
  -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')
echo "control-plane is now $CP_IP"

# 2. update Cilium's k8sServiceHost and restart it
helm upgrade cilium cilium/cilium --version 1.19.4 -n kube-system \
  --reuse-values --set k8sServiceHost="$CP_IP"
  
kubectl -n kube-system rollout restart ds/cilium deploy/cilium-operator

# 3. wait for it to come up
kubectl -n kube-system rollout status ds/cilium --timeout=240s
```
### To work cilium properlly, demonset (ds) and deployment in ns(kube-system) need to run well.

Expected after this: all `cilium-*` pods `1/1 Running`, `cilium-operator` `1/1 Running`,
and `kubectl get nodes` shows all 4 nodes `Ready`.

> If the `cilium` helm repo is missing: `helm repo add cilium https://helm.cilium.io/ && helm repo update`

### What `rollout restart ds/cilium deploy/cilium-operator` means

It's kubectl's `<resource-type>/<name>` shorthand — the one command restarts **two**
different objects:

| Token | Resource type | What it is |
|-------|---------------|-----------|
| `ds/cilium` | **DaemonSet** (`ds`) | the Cilium **agent** — one pod on *every* node (that's why there are 4 `cilium-*` pods) |
| `deploy/cilium-operator` | **Deployment** (`deploy`) | the Cilium **operator** — cluster-wide coordinator (IPAM, CRDs), 2 replicas for HA |

- The agent is a **DaemonSet** because the CNI must run on each node to wire up pod
  networking there. The operator is a **Deployment** because it's cluster-level and
  doesn't need to be on every node.
- `rollout restart` does a **graceful rolling restart** (recreates pods gradually) rather
  than deleting them — the new pods pick up the updated `k8sServiceHost` from the Helm
  upgrade above.
- Handy aliases: `po`=pods, `deploy`=deployments, `ds`=daemonsets, `sts`=statefulsets,
  `svc`=services, `ns`=namespaces, `cm`=configmaps. Full list: `kubectl api-resources`.

---

## Step 3 — Recreate the stranded `Unknown` pods

Once the network (Cilium) is healthy, clear the ghost pods so their controllers
(Deployments / StatefulSets) recreate fresh ones:

```bash
kubectl delete pod -n argocd --all
kubectl delete pod -n gatekeeper-system --all
# add any other namespace that still shows Unknown pods
```

Watch them come back:

```bash
kubectl get pods -n argocd -w        # wait for all 1/1 Running, then Ctrl+C
```

---

## Step 4 — Verify the platform is healthy

```bash
# Argo CD control plane
kubectl get pods -n argocd

# Argo CD apps (should be Synced / Healthy)
kubectl get applications -n argocd

# Gatekeeper
kubectl get pods -n gatekeeper-system
kubectl get constrainttemplates
kubectl get constraints

# your tenant namespaces
kubectl get ns | grep -E 'team|grc'
```

To reach the Argo CD UI again (ingress is on the control-plane node):
- Browser: <http://argocd.localhost>  (http, not https — server is in insecure mode)
- Admin password:
  ```bash
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
  ```

---

## Gatekeeper bootstrap (only if the policies are stuck)

Gatekeeper has a **chicken-and-egg**: a `Constraint` needs a CRD that only exists
*after* its `ConstraintTemplate` is applied (Gatekeeper generates it). The GitOps setup
now splits this into two Argo apps — **`gatekeeper-templates`** (sync-wave 1) and
**`gatekeeper-constraints`** (sync-wave 2) — so a fresh cluster bootstraps itself in order.

If they still get stuck (e.g. `gatekeeper-policies`/`-constraints` shows
`OutOfSync` with *"one or more synchronization tasks are not valid"*), bootstrap the
CRDs manually once, then let Argo take over:

```bash
# 1. apply the templates directly  -> Gatekeeper generates the constraint CRDs
kubectl apply -f k8s-idp/platform/opa-gatekeeper/templates/
sleep 10
kubectl get crd | grep -E 'blocklatesttag|requireresourcelimits|requireteamlabels'

# 2. apply the constraints (their CRDs now exist)
kubectl apply -f k8s-idp/platform/opa-gatekeeper/contraints/

# 3. let Argo reconcile
argocd app sync gatekeeper-templates --core
argocd app sync gatekeeper-constraints --core
```

> Gotcha that caused this once: a `ConstraintTemplate`'s `metadata.name` **must equal
> the lowercase of its `spec.crd.spec.names.kind`** (e.g. kind `BlockLatestTag` →
> name `blocklatesttag`). A mismatch makes Gatekeeper silently reject the template, so
> its CRD is never created and the whole sync stays invalid.

---

## Notes / gotchas

- **kubectl works even when Cilium is down** — it hits the API server directly, so don't
  be fooled into thinking the cluster is fine just because `kubectl` responds.
- **The IP changes every restart**, so re-run Step 2 each time (it auto-detects the IP).
- **ingress-nginx controller** must run on the control-plane node (it has the
  `ingress-ready=true` label and the host `:80/:443` port mappings). If the ingress stops
  working after a restart, check it's still pinned there:
  `kubectl get pod -n ingress-nginx -o wide`.
- **Permanent alternative:** to avoid this entirely you'd pin the kind node IPs or stop
  rebooting the host with the cluster running. For a dev box, running this runbook after
  each reboot is the pragmatic path.
- If `argocd` CLI says `configmap "argocd-cm" not found`, it's core-mode looking in the
  wrong namespace — run `kubectl config set-context --current --namespace=argocd` (Step 0).

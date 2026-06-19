# Global Istio Gateway + TLS — Project Notes

End-to-end notes for the global Istio edge gateway, TLS termination, the service-mesh
mTLS chain, and the Cilium integration gotchas found while building it.

Last verified: 2026-06-16. Cluster: `idp-cluster` (kind, 4 nodes, Cilium 1.19.4 CNI,
kube-proxy replacement). Istio 1.29.2.

---

## 1. Architecture

```
curl https://finance.hellocloud.io/grc/audits
   │  (HTTPS, TLS terminates at the edge)
   ▼
[ global-istio-gateway ]              ns: global-istio-ingress   (LoadBalancer 172.19.255.200)
   │  global-routes VirtualService: rewrite public path -> team path, forward on :80
   ▼
[ grc / payments / retail team ingress gateway ]   ns: <team>-ingress   (ClusterIP)
   │  team Gateway + VirtualService: match /audits -> service
   ▼
[ fraud-svc ] -> [ audit-svc ] -> [ sanction-svc ]   ns: grc-team   (mTLS, STRICT)
```

Two terminating gateways in series: a single external **global** gateway, then the
existing per-team ingress gateways. The global gateway is the only `LoadBalancer`;
the team gateways stay `ClusterIP` (reached internally by the global gateway).

### Public path map (global-routes VirtualService)

| Public path | rewritten to | team ingress gateway (:80) |
|-------------|--------------|----------------------------|
| `/retail-banking/customer-profile-svc` | `/accounts` | `retail-banking-istio-ingressgateway.retail-banking-ingress` |
| `/payments/transactions` | `/transactions` | `payments-istio-ingressgateway.payments-ingress` |
| `/grc/audits` | `/audits` | `grc-istio-ingressgateway.grc-ingress` |

`destination.host` in a VirtualService must be a **Service DNS name** — never a Gateway
or VirtualService object name. The team ingress gateway is itself a Service, so we
address it by `<svc>.<ns>.svc.cluster.local`.

---

## 2. Files

| File | Purpose |
|------|---------|
| `global-istio-gw/00-namespace.yaml` | `global-istio-ingress` namespace (no injection — it's a gateway) |
| `global-istio-gw/01-global-gateway.yaml` | `Gateway`: HTTPS :443 SIMPLE on `finance.hellocloud.io` |
| `global-istio-gw/02-global-virtualservice.yaml` | `VirtualService`: public path → team gateways |
| `global-istio-gw/kustomization.yaml` | bundles the three above |
| `istio/minimal-profile.yaml` | IstioOperator; defines all gateway **pods** incl. `global-istio-ingressgateway` (LoadBalancer) |
| `clusters/prod/argocd/istio-global.yaml` | ArgoCD Application syncing `global-istio-gw/` |
| `cluster-with-cilium/cilium-lb-ippool.yaml`, `cilium-l2-announcement.yaml` | Cilium LB-IPAM pool + L2 announce (external IP, no MetalLB) |
| `apps/grc/00-namespace.yaml` | grc-team namespace — **must** have `istio-injection: enabled` |
| `istio/grc/grc-peerauthentication.yaml` | grc-team STRICT mTLS |
| `istio/grc/grc-destination.yaml` | `*.grc-team.svc...` ISTIO_MUTUAL DestinationRule |

GitOps note: ArgoCD apps use `selfHeal: true`. Any manual `kubectl apply`/`label` that
isn't in Git gets reverted on the next sync — commit changes, don't rely on live edits.

---

## 3. TLS modes (Istio Gateway `server.tls.mode`)

Two families:

| Family | Modes | Who decrypts | Routes on HTTP path? |
|--------|-------|--------------|----------------------|
| **Terminate** | SIMPLE, MUTUAL, OPTIONAL_MUTUAL, ISTIO_MUTUAL | the gateway | yes |
| **Pass-through** | PASSTHROUGH, AUTO_PASSTHROUGH | the backend pod | no (SNI only) |

- **SIMPLE** — one-way TLS, server cert only (normal HTTPS). ← what we deployed
- **MUTUAL** — also require + validate a client cert (`caCertificates`).
- **OPTIONAL_MUTUAL** — client cert requested but optional.
- **ISTIO_MUTUAL** — mTLS using Istio-managed workload certs; all other TLS fields empty.
- **PASSTHROUGH** — forward encrypted by SNI to a VirtualService TLS route.
- **AUTO_PASSTHROUGH** — passthrough with destination encoded in SNI (multi-cluster).

`server.tls.mode` (north-south, ingress) is a different setting from `PeerAuthentication`
mTLS (east-west, pod-to-pod). Don't conflate them.

---

## 4. SIMPLE TLS PoC (deployed, working)

```bash
# 1. self-signed leaf cert for the host (SAN is required, not just CN)
openssl req -x509 -newkey rsa:2048 -nodes -days 365 \
  -keyout finance.key -out finance.crt \
  -subj "/CN=finance.hellocloud.io/O=HelloCloudBank" \
  -addext "subjectAltName=DNS:finance.hellocloud.io"

# 2. secret in the GATEWAY POD's namespace (SDS reads it there)
kubectl -n global-istio-ingress create secret tls finance-tls \
  --cert=finance.crt --key=finance.key

# 3. gateway already has the :443 SIMPLE block referencing finance-tls
kubectl apply -k k8s-idp/global-istio-gw

# 4. proof (no -k; verify against our cert)
curl -v --cacert finance.crt \
  --resolve finance.hellocloud.io:443:172.19.255.200 \
  https://finance.hellocloud.io/grc/audits
```

Proof lines: `SSL connection using TLSv1.3`, `subject: CN=finance.hellocloud.io`,
`SSL certificate verify ok`, then `HTTP/2 200`.

Cert note: `openssl req -x509 ...` makes a **self-signed leaf** (issuer == subject). It
serves as both the server cert and its own trust anchor — that's why `--cacert finance.crt`
(the leaf itself) verifies. Real PKI has a separate root CA → leaf chain. The `finance.key`
is gitignored (`*.key`); the secret is created manually and is NOT in Git.

---

## 5. External IP without MetalLB (Cilium LB-IPAM + L2)

Cilium provides LoadBalancer IPs natively. Required pieces:

1. `CiliumLoadBalancerIPPool` (apiVersion **cilium.io/v2** in 1.19) — pool `172.19.255.200-250`
   (high in the kind docker subnet `172.19.0.0/16`, above the node IPs `172.19.0.2-5`).
2. `CiliumL2AnnouncementPolicy` (**cilium.io/v2alpha1**) — a node ARP-answers for the IP on `eth0`.
3. L2 announcements enabled **via Helm** (not `cilium config set`):
   ```bash
   helm upgrade cilium cilium/cilium --version 1.19.4 -n kube-system --reuse-values \
     --set l2announcements.enabled=true \
     --set k8sClientRateLimit.qps=10 --set k8sClientRateLimit.burst=20
   ```
   GOTCHA: enabling L2 at runtime (`cilium config set`) leaves the cilium ServiceAccount
   without `leases` RBAC → leader election fails (`Error retrieving lease lock ... forbidden`)
   → no node announces → IP assigned but unreachable. The Helm value grants the RBAC.

Result: `global-istio-ingressgateway` Service gets EXTERNAL-IP `172.19.255.200`.

---

## 6. Service-mesh mTLS chain (grc-team)

Enforced by:
- `PeerAuthentication` STRICT (grc-team) — services require mTLS inbound.
- `DestinationRule` `*.grc-team.svc.cluster.local` ISTIO_MUTUAL — clients dial mTLS.
- `istio-injection: enabled` on the grc-team namespace — so pods get sidecars (2/2).

All three are required together. Sidecar terminates mTLS and forwards plaintext to the app.

---

## 7. Troubleshooting log (real issues hit, in order)

| Symptom | Root cause | Fix |
|---------|-----------|-----|
| `curl :80 connection refused` | edge IP was a ClusterIP / no external IP | use the LoadBalancer EXTERNAL-IP; install Cilium LB-IPAM |
| EXTERNAL-IP `<pending>` | no `CiliumLoadBalancerIPPool` + L2 off | add pool + L2 policy + enable L2 via Helm |
| IP assigned but unreachable, `ip neigh FAILED` | L2 enabled at runtime → cilium SA lacks `leases` RBAC | enable L2 via **Helm** (adds RBAC) |
| `:443 connection refused` | gateway `:443` block edited on disk but not applied (ArgoCD selfHeal also reverted it) | commit to Git + `kubectl apply -k` / ArgoCD sync |
| `503 UF, TLS_error WRONG_VERSION_NUMBER` | grc-team had STRICT mTLS but **no sidecars** (injection commented out) | uncomment `istio-injection: enabled`, restart deploys → 2/2 |
| `500, fraud→audit EOF`, `PassthroughCluster` to pod-IP:targetport | **Cilium socket-LB Full coverage** rewrites ClusterIP→podIP inside the pod, before Envoy → plaintext → STRICT drops it | `socketLB.hostNamespaceOnly=true` (Helm) + restart cilium → coverage `Hostns-only` |
| `x-forwarded-proto: http` at backend | 2nd (grc) gateway terminates plain HTTP :80 and overwrites XFP | EnvoyFilter forcing `https` (Option A), or per-gateway `gatewayTopology.numTrustedProxies: 1` (Option B) |

### Key diagnostic signatures
- `WRONG_VERSION_NUMBER` = TLS speaker hitting a plaintext listener (missing sidecar).
- `NR filter_chain_not_found` (inbound) = plaintext arrived at a STRICT (mTLS-only) listener.
- `PassthroughCluster` to **pod-IP:targetPort** = traffic bypassed mesh routing (Cilium socket-LB).
- Gateway hops work but app→app fails = gateways route by L7 cluster (apply mTLS themselves);
  only sidecar-intercepted traffic is affected by socket-LB.

### Cilium + Istio rule of thumb
With `kubeProxyReplacement=true`, set **`socketLB.hostNamespaceOnly=true`** so socket-LB
does NOT translate Service VIPs inside pod namespaces — letting Istio sidecars see the
ClusterIP and apply mesh routing + mTLS. Trust `cilium-dbg status --verbose`
(`Socket LB Coverage`) over the `bpf-lb-sock` configmap key, which can read `false`
while the feature is actually on.

---

## 8. x-forwarded-proto across two gateways

Each terminating gateway rewrites `x-forwarded-proto` to the scheme **it** received
(`use_remote_address` edge behavior). The grc gateway receives plain HTTP on :80, so it
stamps `http`, wiping the `https` the global gateway set.

To preserve `https` to the backend:
- **Option A:** EnvoyFilter (Lua) on the grc gateway forcing `x-forwarded-proto: https`.
- **Option B (cleaner):** per-gateway `gatewayTopology.numTrustedProxies: 1` so the grc
  gateway trusts the 1 proxy in front (the global gateway) and preserves the header.
  Scope to the grc gateway only — the global gateway is the real edge (0 proxies in front).

Determine the count from the XFF chain the grc gateway forwards, e.g.
`x-forwarded-for: 10.0.0.70, 10.0.3.123` = `[client, global-gw]` → 1 proxy in front → `1`.

Check current value:
```bash
istioctl proxy-config listener deploy/grc-istio-ingressgateway.grc-ingress -o json | grep -i xffNumTrustedHops
```

---

## 9. Quick verification

```bash
GW=172.19.255.200
# TLS + full chain
curl -v --cacert finance.crt --resolve finance.hellocloud.io:443:$GW https://finance.hellocloud.io/grc/audits
# external IP
kubectl get svc -n global-istio-ingress global-istio-ingressgateway
# cilium socket-LB coverage (want Hostns-only)
CP=$(kubectl get pod -n kube-system -l k8s-app=cilium -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n kube-system "$CP" -c cilium-agent -- cilium-dbg status --verbose | grep "Socket LB Coverage"
# grc-team sidecars (want 2/2)
kubectl get pods -n grc-team
# inspect served cert
openssl s_client -connect $GW:443 -servername finance.hellocloud.io </dev/null 2>/dev/null | openssl x509 -noout -subject -issuer -dates
```

## 10. Current status (2026-06-16)
- Global gateway: `443/HTTPS SIMPLE`, EXTERNAL-IP `172.19.255.200` ✅
- Cilium Socket LB Coverage: `Hostns-only` ✅
- grc-team: injection enabled, pods 2/2, STRICT mTLS ✅
- End-to-end `https://finance.hellocloud.io/grc/audits` → **HTTP 200** ✅
- `x-forwarded-proto`: currently `http` (EnvoyFilter removed); Option B (`numTrustedProxies`) pending.

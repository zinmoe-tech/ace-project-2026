# HelloCloudBank — Istio Service Mesh Gateway

A production-pattern retail banking microservices platform on a local Kind cluster.
Demonstrates a full security, routing, observability, and autoscaling stack using
**Istio**, **Kong**, **Keycloak**, **Prometheus**, and **Grafana**.

---

## Architecture

![overview](asset/globalkong-istio-gateway.png)




### Security Layers (applied left to right per request)

```
Client Request
  → [1] JWT Signature Valid?      (RequestAuthentication — Keycloak JWKS)
  → [2] Has JWT token?            (AuthorizationPolicy DENY — deny-no-jwt)
  → [3] Correct group in token?   (AuthorizationPolicy DENY — deny-wrong-jwt)
  → [4] SPIFFE identity allowed?  (AuthorizationPolicy ALLOW — pod-to-pod)
  → [5] Group matches namespace?  (AuthorizationPolicy ALLOW — require-jwt)
  → Microservice
```

---

## Stack

| Component | Version | Role |
|-----------|---------|------|
| Kind | v1.34 | Local Kubernetes cluster (4 nodes) |
| Istio | 1.29.2 | Service mesh, mTLS, JWT enforcement |
| Kong | OSS 3.9.1 | Global API gateway (external entry) |
| Keycloak | 26.0.0 | Identity provider, JWT issuer |
| MetalLB | v0.15.3 | LoadBalancer IPs for Kind |
| Prometheus | v2.53.0 | Metrics collection |
| Grafana | 11.1.0 | Metrics dashboard |
| metrics-server | v0.7.2 | CPU/memory metrics for HPA |

---

## Prerequisites

```bash
# Required tools
kind       # v1.34+
kubectl
helm
istioctl   # 1.29.2  (from istio-1.29.2/ directory)
```

---

## Setup — Step by Step

### Step 1 — Create Kind Cluster

```bash
cd istio-gateway
bash kind-cluster-setup/setupkindcluster134.sh
```

This creates a 4-node cluster (`134-control-plane`, `134-worker`, `134-worker2`, `134-worker3`),
installs MetalLB, and assigns the IP pool `172.18.255.190–199`. Context renamed to `134`.

Verify:
```bash
kubectl get nodes --context 134
kubectl get ipaddresspools -n metallb-system
```

---

### Step 2 — Install Gateway API CRDs

```bash
kubectl apply --server-side \
  -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.1/standard-install.yaml
```

Verify:
```bash
kubectl api-resources --api-group=gateway.networking.k8s.io
```

---

### Step 3 — Install Kong Ingress Controller

```bash
helm repo add kong https://charts.konghq.com && helm repo update

helm upgrade --install global-kic kong/ingress \
  --namespace global-kic --create-namespace \
  --set gateway.proxy.type=LoadBalancer \
  --set controller.ingressController.env.gateway_api_controller_name=konghq.com/global-kong-gateway-controller
```

Verify (Kong gets `172.18.255.190`):
```bash
kubectl get svc -n global-kic
```

---

### Step 4 — Install Istio

```bash
istioctl install -f istio-gateway/minimal-profile.yaml -y
```

This installs `istiod` and three team ingress gateways — all as **ClusterIP** (internal only):

| Gateway | Namespace |
|---------|-----------|
| `retail-banking-istio-ingressgateway` | `retail-banking-ingress` |
| `payments-istio-ingressgateway` | `payments-ingress` |
| `grc-istio-ingressgateway` | `grc-ingress` |

Verify:
```bash
kubectl get pods -n istio-system
kubectl get svc -n retail-banking-ingress
kubectl get svc -n payments-ingress
kubectl get svc -n grc-ingress
```

---

### Step 5 — Enable Istio Sidecar Injection

The app namespaces are created with sidecar injection enabled by the app manifests.
Verify after Step 6:
```bash
kubectl get ns retail-banking-team payments-team grc-team --show-labels
# Should show: istio-injection=enabled
```

---

### Step 6 — Deploy Microservices

```bash
kubectl apply -f istio-gateway/apps/retail-banking/
kubectl apply -f istio-gateway/apps/payments/
kubectl apply -f istio-gateway/apps/grc/
```

Each namespace has 3 microservices that chain together:

| Namespace | Chain |
|-----------|-------|
| `retail-banking-team` | `customer-profile-svc` → `account-svc` → `statement-svc` |
| `payments-team` | `transfer-svc` → `payment-gateway-svc` → `fx-svc` |
| `grc-team` | `fraud-svc` → `audit-svc` → `sanction-svc` |

Verify (each pod shows `2/2` — app + Istio sidecar):
```bash
kubectl get pods -n retail-banking-team
kubectl get pods -n payments-team
kubectl get pods -n grc-team
```

---

### Step 7 — Deploy Kong Global Gateway Routes

```bash
kubectl apply -f istio-gateway/global-api-gateway/
```

Creates the `GatewayClass`, `Gateway`, `HTTPRoute`, and `ReferenceGrant` in each team namespace.

HTTPRoute path rewriting:

| Public path | Routes to |
|-------------|-----------|
| `/retail-banking/*` | `retail-banking-ingress` service |
| `/payments/*` | `payments-ingress` service |
| `/grc/*` | `grc-ingress` service |

Verify:
```bash
kubectl get gateway -n global-kic
kubectl get httproute -A
kubectl get referencegrant -A
```

---

### Step 8 — Deploy Team Istio Routes

```bash
kubectl apply -k istio-gateway/team-istio-routes
```

Creates one Istio `Gateway` + `VirtualService` per team that routes
from the ingress gateway to the lead microservice.

Verify:
```bash
kubectl get gateway.networking.istio.io -A
kubectl get virtualservice -A
```

Test routing (no security yet):
```bash
KONG_IP=172.18.255.190
curl -H "Host: finance.hellocloud.io" http://$KONG_IP/retail-banking/customer-profile-svc
curl -H "Host: finance.hellocloud.io" http://$KONG_IP/payments/transactions
curl -H "Host: finance.hellocloud.io" http://$KONG_IP/grc/audits
```

---

### Step 9 — Apply Security Policies

#### 9a — Mesh-wide mTLS STRICT

```bash
kubectl apply -f istio-gateway/security/peer-authentication.yaml
```

All pod-to-pod traffic is now encrypted and authenticated with mutual TLS.
Plain HTTP between sidecars is rejected immediately.

#### 9b — SPIFFE Pod-to-Pod Authorization

```bash
kubectl apply -f istio-gateway/security/authz-retail-banking-ingress.yaml
kubectl apply -f istio-gateway/security/authz-retail-banking.yaml
kubectl apply -f istio-gateway/security/authz-payments-ingress.yaml
kubectl apply -f istio-gateway/security/authz-payments.yaml
kubectl apply -f istio-gateway/security/authz-grc-ingress.yaml
kubectl apply -f istio-gateway/security/authz-grc.yaml
```

Each file adds:
- A **deny-all** default policy for the namespace
- **ALLOW** rules based on SPIFFE workload identity (service account + namespace)

Allowed call chains:

```
retail-banking-ingress → customer-profile-svc → account-svc → statement-svc
payments-ingress       → transfer-svc → payment-gateway-svc → fx-svc
grc-ingress            → fraud-svc → audit-svc → sanction-svc
```

Verify (should return `403` without a token):
```bash
curl -s -o /dev/null -w "%{http_code}" \
  -H "Host: finance.hellocloud.io" http://172.18.255.190/retail-banking/customer-profile-svc
# 403
```

---

### Step 10 — Deploy Keycloak

```bash
kubectl apply -f istio-gateway/keycloak/00-namespace.yaml
kubectl apply -f istio-gateway/keycloak/01-keycloak.yaml
```

Keycloak gets IP `172.18.255.191`. Admin UI: **http://keycloak.hellocloud.io:8080/admin**
Login: `admin` / `admin`

Add to `/etc/hosts`:
```
172.18.255.191  keycloak.hellocloud.io
```

#### Keycloak Configuration (manual, one-time setup)

In the Keycloak admin UI:

1. **Create realm**: `hellocloudbank`
2. **Create clients**: `retail-banking-client`, `payments-client`, `grc-client`, `admin-client`
   - Each client: `Client authentication ON`, `Direct access grants ON`
3. **Create groups**: `retail-group`, `payments-group`, `grc-group`
   - Or run: `bash istio-gateway/keycloak/04-groups.sh`
4. **Create users**:

| User | Password | Group | Client |
|------|----------|-------|--------|
| `john` | `john123` | `retail-group` | `retail-banking-client` |
| `steve` | `steve123` | `payments-group` | `payments-client` |
| `messi` | `messi123` | `grc-group` | `grc-client` |
| `admin-user` | `admin123` | _(none)_ | `admin-client` |

5. **Add Group Membership mapper** (required for `groups` claim in JWT):
   - Client → `retail-banking-client` → Client Scopes → `retail-banking-client-dedicated`
   - Mappers → Configure a new mapper → **Group Membership**
   - Name: `groups` | Token Claim Name: `groups` | Full group path: **OFF** | Add to access token: **ON**
   - Repeat for `payments-client`, `grc-client`, `admin-client`

6. **Set token lifetime** to 1 hour:
   - Realm Settings → Tokens → Access Token Lifespan → `1 Hour`

#### Current client secrets (update if rotated):

| Client | Secret |
|--------|--------|
| `retail-banking-client` | `c9bI4S3HAcB9LYaJES241py61Wc5Ues1` |
| `payments-client` | `KkCk1GmVTmNADrr0Qy2LjlTiQWghUOMR` |
| `grc-client` | `d3PFwfYOzTfCOqyMeUBAbMwM25XZPvtq` |
| `admin-client` | `fHOjQPS22PxfZUSymymH8hbfroxYBijg` |

---

### Step 11 — Apply JWT Request Authentication

```bash
kubectl apply -f istio-gateway/keycloak/02-request-authentication.yaml
```

Tells Istio sidecars to validate JWT tokens using Keycloak's public keys.

| Condition | Result |
|-----------|--------|
| Valid JWT | Passed to AuthorizationPolicy |
| Invalid / tampered JWT | `401` — rejected immediately by Istio |
| No JWT | Passed through (handled by deny-no-jwt policy) |

---

### Step 12 — Apply Group-Based JWT Authorization

```bash
kubectl apply -f istio-gateway/keycloak/10-authz-policy-retail-group.yaml
```

27 policies total (3 namespaces × 3 pods × 3 policy types):

| Policy type | Action | Condition |
|-------------|--------|-----------|
| `deny-no-jwt-*` | DENY | Request has no JWT token |
| `deny-wrong-jwt-*` | DENY | JWT present but `groups` claim doesn't match namespace |
| `require-jwt-*` | ALLOW | JWT present and `groups` claim matches namespace |

Access matrix:

| User | Token group | retail-banking | payments | grc |
|------|-------------|----------------|----------|-----|
| john | `retail-group` | 200 | 403 | 403 |
| steve | `payments-group` | 403 | 200 | 403 |
| messi | `grc-group` | 403 | 403 | 200 |
| admin-user | _(exempt)_ | 200 | 200 | 200 |

`admin-user` bypasses deny-wrong-jwt via `notValues: ["admin-user"]` exemption — no separate admin policy needed.

---

## Observability

### Step 13 — Deploy Prometheus + Grafana

```bash
kubectl apply -f istio-gateway/observability/01-monitoring-ns.yaml
kubectl apply -f istio-gateway/observability/02-prometheus.yaml
kubectl apply -f istio-gateway/observability/03-grafana.yaml
kubectl apply -f istio-gateway/observability/04-telemetry.yaml
```

| Tool | External IP | Port | Login |
|------|-------------|------|-------|
| Prometheus | `172.18.255.192` | `9090` | — |
| Grafana | `172.18.255.193` | `3000` | `admin` / `admin` |

Grafana home dashboard: **"HelloCloudBank - Live User Sessions"** (loads automatically)

Dashboard panels:
- Live request rate per service (req/s)
- Request rate per namespace (team activity)
- Auth error rate — 401 / 403 (JWT failures)
- P99 request latency per service
- Total request rate, success rate, active services stats

Prometheus scrapes:
- `istiod` control plane (port 15014)
- All Istio sidecar proxies in all 3 namespaces (port 15090 `/stats/prometheus`)

Telemetry — Envoy access logs enabled for all 3 namespaces:
```bash
kubectl logs <pod> -n retail-banking-team -c istio-proxy
kubectl logs <pod> -n payments-team -c istio-proxy
kubectl logs <pod> -n grc-team -c istio-proxy
```

### Check Keycloak Live Sessions

```bash
bash istio-gateway/observability/05-keycloak-sessions.sh
```

Shows which users are actively logged in and their session start times per client.

---

## Autoscaling

### Step 14 — Deploy metrics-server and HPA

```bash
kubectl apply -f istio-gateway/autoscaling/01-metrics-server.yaml
kubectl apply -f istio-gateway/autoscaling/02-hpa.yaml
```

HPA is configured for all 9 microservices:

| Setting | Value |
|---------|-------|
| CPU trigger | actual CPU > **5m** per pod (AverageValue) |
| Min replicas | 1 |
| Max replicas | 2 |

> **Why AverageValue instead of Utilization?**
> The fake-service (nicholasjackson/fake-service) is a lightweight Go HTTP proxy.
> Even under 1800 concurrent connections it only uses 1–8m CPU — well below
> 80% of 100m (= 80m). Using `AverageValue: 5m` triggers scale-out as soon
> as load pushes CPU above 5 millicores, which is observable under hey load.

Verify:
```bash
kubectl get hpa -A
# TARGETS shows current CPU% / 80%
```

### Load Test (trigger HPA)

Uses `hey` — a Go-based HTTP benchmarker. Spawns 9 workers (one per endpoint) with 200 persistent connections each = **1800 total concurrent connections**.

```bash
bash istio-gateway/observability/load-test.sh
```

Stop with `Ctrl+C`. Tokens auto-refresh every 55 minutes.

Watch HPA scale in real time:
```bash
watch -n 3 "
echo '============================================================'
echo '  POD CPU / MEMORY'
echo '============================================================'
printf '%-25s %-35s %-8s %-8s\n' NAMESPACE POD CPU MEMORY
echo '------------------------------------------------------------'
kubectl top pods -A --no-headers | grep -E 'retail-banking-team|payments-team|grc-team' | awk '{printf \"%-25s %-35s %-8s %-8s\n\", \$1, \$2, \$3, \$4}'
echo ''
echo '============================================================'
echo '  HPA STATUS'
echo '============================================================'
printf '%-25s %-30s %-12s %-5s %-5s %-8s\n' NAMESPACE NAME TARGET MIN MAX REPLICAS
echo '------------------------------------------------------------'
kubectl get hpa -A --no-headers | grep -E 'retail-banking-team|payments-team|grc-team' | awk '{printf \"%-25s %-30s %-12s %-5s %-5s %-8s\n\", \$1, \$2, \$5, \$6, \$7, \$8}'
"
```

When CPU exceeds 80%, REPLICAS flips from `1 → 2`.

---

## Testing

### Get tokens

```bash
JOHN_TOKEN=$(curl -s -X POST \
  http://keycloak.hellocloud.io:8080/realms/hellocloudbank/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=retail-banking-client&client_secret=c9bI4S3HAcB9LYaJES241py61Wc5Ues1&username=john&password=john123&grant_type=password" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

MESSI_TOKEN=$(curl -s -X POST \
  http://keycloak.hellocloud.io:8080/realms/hellocloudbank/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=grc-client&client_secret=d3PFwfYOzTfCOqyMeUBAbMwM25XZPvtq&username=messi&password=messi123&grant_type=password" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

ADMIN_TOKEN=$(curl -s -X POST \
  http://keycloak.hellocloud.io:8080/realms/hellocloudbank/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=admin-client&client_secret=fHOjQPS22PxfZUSymymH8hbfroxYBijg&username=admin-user&password=admin123&grant_type=password" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")
```

### Expected results

```bash
KONG=172.18.255.190

# john (retail-group) — 200 on retail, 403 on others
curl -s -o /dev/null -w "HTTP: %{http_code}\n" -H "Host: finance.hellocloud.io" \
  -H "Authorization: Bearer $JOHN_TOKEN" http://$KONG/retail-banking/customer-profile-svc
# HTTP: 200

curl -s -o /dev/null -w "HTTP: %{http_code}\n" -H "Host: finance.hellocloud.io" \
  -H "Authorization: Bearer $JOHN_TOKEN" http://$KONG/payments/transactions
# HTTP: 403

# messi (grc-group) — 200 on grc only
curl -s -o /dev/null -w "HTTP: %{http_code}\n" -H "Host: finance.hellocloud.io" \
  -H "Authorization: Bearer $MESSI_TOKEN" http://$KONG/grc/audits
# HTTP: 200

# admin-user — 200 on all
curl -s -o /dev/null -w "HTTP: %{http_code}\n" -H "Host: finance.hellocloud.io" \
  -H "Authorization: Bearer $ADMIN_TOKEN" http://$KONG/retail-banking/customer-profile-svc
# HTTP: 200

curl -s -o /dev/null -w "HTTP: %{http_code}\n" -H "Host: finance.hellocloud.io" \
  -H "Authorization: Bearer $ADMIN_TOKEN" http://$KONG/payments/transactions
# HTTP: 200
```

### Decode JWT token

```bash
echo $JOHN_TOKEN | cut -d'.' -f2 | python3 -c "
import sys,base64,json
p=sys.stdin.read().strip()
p+='='*(4-len(p)%4)
print(json.dumps(json.loads(base64.urlsafe_b64decode(p)), indent=2))
"
# Check: "groups": ["retail-group"]
```

---

## File Structure

```
istio-gateway/
│
├── apps/                              # Microservice manifests
│   ├── retail-banking/               # Namespace + customer-profile + account + statement
│   ├── payments/                     # Namespace + transfer + payment-gateway + fx
│   └── grc/                          # Namespace + fraud + audit + sanction
│
├── global-api-gateway/               # Kong global gateway
│   ├── 00-namespaces.yaml            # global-kic, global-api-gateway-ns
│   ├── 01-gatewayclass.yaml          # GatewayClass for Kong
│   ├── 02-global-gateway.yaml        # Kong Gateway (LoadBalancer)
│   ├── 03-global-httproute.yaml      # HTTPRoute with path rewriting
│   └── reference-grants/            # Allows Kong to route to team namespaces
│
├── team-istio-routes/                # Istio Gateway + VirtualService per team
│   ├── retail-banking/
│   ├── payments/
│   └── grc/
│
├── keycloak/                         # Identity provider
│   ├── 00-namespace.yaml
│   ├── 01-keycloak.yaml              # Keycloak deployment
│   ├── 02-request-authentication.yaml # JWT signature validation
│   ├── 10-authz-policy-retail-group.yaml # Group-based JWT authz (27 policies)
│   ├── how-to.md                     # Keycloak setup guide
│   └── how-to-write-policy.md        # JWT policy authoring reference
│
├── security/                         # Istio security controls
│   ├── peer-authentication.yaml      # Mesh-wide mTLS STRICT
│   ├── authz-retail-banking.yaml     # SPIFFE deny-all + allow chain (retail)
│   ├── authz-payments.yaml           # SPIFFE deny-all + allow chain (payments)
│   ├── authz-grc.yaml                # SPIFFE deny-all + allow chain (grc)
│   ├── authz-retail-banking-ingress.yaml  # Ingress gateway security
│   ├── authz-payments-ingress.yaml
│   └── authz-grc-ingress.yaml
│
├── observability/                    # Monitoring stack
│   ├── 01-monitoring-ns.yaml         # monitoring namespace (no Istio injection)
│   ├── 02-prometheus.yaml            # Prometheus + scrape config
│   ├── 03-grafana.yaml               # Grafana + live sessions dashboard
│   ├── 04-telemetry.yaml             # Envoy access logs for all namespaces
│   ├── 05-keycloak-sessions.sh       # Script: query active Keycloak sessions
│   └── load-test.sh                  # hey-based load generator (1800 concurrent connections)
│
├── autoscaling/                      # Horizontal Pod Autoscaler
│   ├── 01-metrics-server.yaml        # metrics-server (kind-compatible)
│   └── 02-hpa.yaml                   # HPA for all 9 services (80% CPU → 2 replicas)
│
├── kind-cluster-setup/               # Cluster bootstrap
│   ├── kindconfig-v134.yaml          # Kind cluster config (4 nodes)
│   ├── metallb-v0153-ipaddress-pool-5.yaml  # MetalLB IP pool 172.18.255.190-199
│   ├── setupkindcluster134.sh        # Full cluster setup script
│   └── teardown.sh                   # Destroy cluster
│
└── minimal-profile.yaml              # Istio IstioOperator — 3 ClusterIP ingress gateways
```

---

## IP Address Map

| Service | IP | Port |
|---------|-----|------|
| Kong Global Gateway | `172.18.255.190` | `80` |
| Keycloak | `172.18.255.191` | `8080` |
| Prometheus | `172.18.255.192` | `9090` |
| Grafana | `172.18.255.193` | `3000` |

---

## Troubleshooting

### 403 on all requests after applying security
```bash
# Check which AuthorizationPolicy is denying
kubectl get authorizationpolicy -A
# Look at Istio proxy logs for the target pod
kubectl logs <pod> -n retail-banking-team -c istio-proxy | tail -20
```

### JWT token not working (401)
```bash
# Check token is not expired
echo $TOKEN | cut -d'.' -f2 | python3 -c "
import sys,base64,json,datetime
p=sys.stdin.read().strip(); p+='='*(4-len(p)%4)
d=json.loads(base64.urlsafe_b64decode(p))
print('Expires:', datetime.datetime.fromtimestamp(d['exp']))
print('Groups:', d.get('groups','MISSING'))
"
```

### groups claim missing from token
The Group Membership mapper is not configured.
Go to Keycloak → Client → Client Scopes → Dedicated scope → Mappers → Add Group Membership mapper.
Token Claim Name must be `groups` (lowercase).

### HPA shows `<unknown>` for TARGETS
metrics-server is not ready yet. Wait 30 seconds and check:
```bash
kubectl get pods -n kube-system | grep metrics-server
kubectl top pods -n retail-banking-team
```

### Grafana shows no data
Prometheus may not be scraping yet. Check targets:
```bash
curl -s http://172.18.255.192:9090/api/v1/targets | python3 -c "
import sys,json; d=json.load(sys.stdin)
for t in d['data']['activeTargets']: print(t['health'], t['labels'].get('job'))
"
# All should show: up  istio-proxy
```

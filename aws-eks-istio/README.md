# Istio on AWS EKS (Terraform)

Stands up the AWS equivalent of the local kind + Cilium setup, so the Istio
project can run on managed Kubernetes.

## Architecture

Three tiers — **Global gateway → grc Domain gateway → microservices**. Only the
global tier is public (LoadBalancer → AWS NLB); the domain gateway and
microservices stay ClusterIP (internal). Same layout as `istio-gateway-cilium/`,
trimmed to grc.

```
                         Internet / users
                            │  Host: grc.ky-cloud.click
                            ▼
                 ┌──────────────────────┐
                 │  AWS NLB  (public)   │   (only public entry point)
                 └──────────────────────┘
 ═══════════════════════════╪═══════════════════════════  AWS account
   VPC 10.0.0.0/16 · 3 AZs · private subnets · NAT          (vpc.tf · eks.tf)
 ═══════════════════════════╪═══════════════════════════
                            │
   EKS cluster · AWS VPC CNI
                            ▼  TIER 1 — global            [global-istio-gw/]
 ┌─ namespace: global-istio-ingress · Service: LoadBalancer (NLB) ─────
 │   global-istio-ingressgateway   (Envoy pod)
 │   Gateway global-istio-gateway :80 · VirtualService global-routes
 │      /  →  grc domain gateway Service
 └──────────────────────────────────────────────────────────────────────
                 │  → grc-istio-ingressgateway.grc-ingress:80
                 ▼  TIER 2 — grc domain        [domain-istio-gateway/grc/]
 ┌─ namespace: grc-ingress · Service: ClusterIP ───────────────────────
 │   grc-istio-ingressgateway   (Envoy pod)
 │   Gateway grc-gateway :80   (VirtualService grc-routes lives in grc-ns)
 │      /  →  fraud-svc:6061
 └──────────────────────────────────────────────────────────────────────
                 │
                 ▼  TIER 3 — microservices     [app/grc/]
 ┌─ namespace: grc-ns ─────────────────────────────────────────────────
 │   fraud-svc (9091) → audit-svc:6062 (9092) → sanction-svc:6063 (9093)
 └──────────────────────────────────────────────────────────────────────

 ┌─ namespace: istio-system · control plane ───────────────────────────
 │   istio-base + istiod          Terraform/Helm: istio.tf
 │   · · · configures both ingress gateways above
 └──────────────────────────────────────────────────────────────────────

 Request path:
   client → global gateway → global-routes → grc domain gateway
          → grc-gateway → grc-routes → fraud → audit → sanction
```

### Files (mirrors istio-gateway-cilium/)

| Path | Role |
|------|------|
| `minimal-profile.yaml` | **Both** ingress gateways (global + grc) in one IstioOperator — ClusterIP |
| `global-istio-gw/` | TIER 1: global Gateway + VirtualService (→ grc domain gw) |
| `domain-istio-gateway/grc/` | TIER 2: grc domain Gateway + VirtualService (→ fraud-svc) |
| `app/grc/` | TIER 3: namespaces + fraud/audit/sanction workloads |

**Who builds what:** Terraform builds the VPC, EKS cluster, and Istio control
plane (`istio-system`). Everything above is applied with `istioctl` + `kubectl`.

## What this creates

| Layer | Resource |
|-------|----------|
| Network | VPC across 3 AZs, private subnets, single NAT gateway |
| Cluster | EKS managed control plane (`kubernetes_version`) |
| Compute | One EKS managed node group (private subnets) |
| Add-ons | CoreDNS, kube-proxy, **AWS VPC CNI** |
| Mesh control plane | `istio-base` + `istiod` via Helm |
| Gateways | `minimal-profile.yaml` via istioctl — global = **LoadBalancer (NLB)**, grc domain = ClusterIP |
| Routing + workloads | `global-istio-gw/` + `domain-istio-gateway/grc/` + `app/grc/` via kubectl |

### Differences from the local kind/Cilium setup
- **CNI is AWS VPC CNI, not Cilium.** Pods get real VPC IPs. There is no
  `cilium_host` router IP, no Cilium LB IPAM / L2 announcements, and no
  kube-proxy replacement.
- The `socketLB.hostNamespaceOnly` mTLS workaround **does not apply** — it was
  Cilium-specific (and there are no sidecars / mTLS in this grc setup anyway).
- The grc gateway is **ClusterIP (internal only)** — no MetalLB / Cilium LB IPAM
  and no AWS load balancer. Reach it in-cluster or via `kubectl port-forward`.

## Prerequisites
- Terraform >= 1.5
- AWS CLI configured with credentials (`aws sts get-caller-identity` works)
- `kubectl` and `istioctl` (matching `istio_version`)

## Deploy

```bash
cd aws-eks-istio
cp terraform.tfvars.example terraform.tfvars   # edit as needed

terraform init
terraform plan
terraform apply
```

Then point kubectl at the cluster (Terraform prints the exact command):

```bash
aws eks update-kubeconfig --region <region> --name idp-cluster
kubectl get nodes
```

## Gateways + routing (after the cluster is up)

Terraform installs only the **control plane** (base + istiod). The gateways,
routing, and workloads are applied in tier order:

```bash
aws eks update-kubeconfig --region <region> --name idp-cluster

# 1. Namespaces (gateway ns must exist before istioctl install)
kubectl apply -f global-istio-gw/00-namespace.yaml
kubectl apply -f app/grc/0-namespace.yaml          # grc-ingress + grc-ns

# 2. Both ingress gateways (global + grc), ClusterIP — one IstioOperator
istioctl install -f minimal-profile.yaml

# 3. TIER 1 — global routing
kubectl apply -f global-istio-gw/01-global-gateway.yaml
kubectl apply -f global-istio-gw/02-global-virtualservice.yaml

# 4. TIER 2 — grc domain routing
kubectl apply -f domain-istio-gateway/grc/gateway-virtualservice.yaml

# 5. TIER 3 — microservices
kubectl apply -f app/grc/3-fraud.yaml
kubectl apply -f app/grc/4-audit.yaml
kubectl apply -f app/grc/5-sanction.yaml
```

### Reach it (public NLB)

Get the global gateway's NLB hostname, then hit it (traverses global → grc
domain → fraud → audit → sanction):

```bash
NLB=$(kubectl -n global-istio-ingress get svc global-istio-ingressgateway \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "$NLB"

curl -H "Host: grc.ky-cloud.click" "http://$NLB/"
```

For real users, point `grc.ky-cloud.click` (a CNAME) at that NLB hostname in DNS;
then `curl http://grc.ky-cloud.click/` works without the `Host` header.

## Destroy

The global gateway has a public NLB, so delete the in-cluster resources **first**
— that removes the LoadBalancer Service, letting AWS tear down the NLB before the
VPC is destroyed:

```bash
kubectl delete -f app/grc/ --ignore-not-found
kubectl delete -f domain-istio-gateway/grc/gateway-virtualservice.yaml --ignore-not-found
kubectl delete -f global-istio-gw/ --ignore-not-found
istioctl uninstall --purge -y          # removes both gateways + control plane

# confirm the NLB is gone before destroying the VPC:
kubectl get svc -A | grep -i loadbalancer || echo "no LB left"

terraform destroy
```

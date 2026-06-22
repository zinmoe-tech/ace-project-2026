# Istio manifests (grc path) — EKS / AWS networking

The AWS equivalent of `istio-gateway-cilium/`, trimmed to the **grc** service.
These are plain Istio CRs — the same ones from the local setup — applied on top
of the EKS cluster + Istio control plane that Terraform creates.

## What's here

```
istio-manifests/
├── namespaces.yaml          grc-ingress, grc-team, global-istio-ingress
├── minimal-profile.yaml     IstioOperator: grc ingress GW (ClusterIP)
│                              + global edge GW (LoadBalancer -> AWS NLB)
├── global-istio-gw/         the global edge: Gateway + VirtualService (routes /grc)
└── domain-istio-gateway/
    └── grc/                 grc Gateway + VirtualService (-> fraud-svc)
```

## Request flow

```
  user
   │  http://<NLB>/grc/audits   (Host: finance.hellocloud.io)
   ▼
 ┌─────────────┐
 │  AWS NLB    │  (from the global GW's LoadBalancer Service)
 └─────────────┘
   │
   ▼  namespace: global-istio-ingress
 ┌──────────────────────────────────────────────┐
 │ global-istio-gateway  (Gateway :80)           │
 │ global-routes         (VirtualService)        │
 │   match /grc/audits  →  rewrite to /audits     │
 └──────────────────────────────────────────────┘
   │  → grc-istio-ingressgateway.grc-ingress.svc.cluster.local:80
   ▼  namespace: grc-ingress
 ┌──────────────────────────────────────────────┐
 │ grc-gateway           (Gateway :80)           │
 └──────────────────────────────────────────────┘
   │
   ▼  namespace: grc-team
 ┌──────────────────────────────────────────────┐
 │ grc-routes            (VirtualService)        │
 │   match /audits  →  fraud-svc:6061             │
 └──────────────────────────────────────────────┘
   │
   ▼
 fraud-svc.grc-team.svc.cluster.local:6061   (your microservice)
```

Two ingress hops on purpose: the **global** gateway is the one public NLB and
owns cross-team routing; the **grc** gateway is internal (ClusterIP) and owns
grc's own paths. The `Host` header stays `finance.hellocloud.io` the whole way,
so both gateways' host matches bind.

## Differences from the cilium version

| Cilium setup | Here (AWS) |
|---|---|
| Cluster + CNI from `cluster-with-cilium/` | EKS + AWS VPC CNI from the Terraform in `../` |
| Global GW external IP via MetalLB / Cilium LB IPAM | Global GW Service → **AWS NLB** (annotations in `minimal-profile.yaml`) |
| `istioctl install` does base + pilot + gateways | Control plane (base + istiod) is installed by **Terraform/Helm**; this profile has them **disabled** and only adds gateways |
| grc STRICT mTLS (PeerAuthentication + DestinationRule) | **Removed** — no sidecar injection, no mTLS on grc-team |

## Prerequisites

1. The Terraform in `../` applied (EKS cluster + istiod running).
2. `kubectl` pointed at the cluster:
   ```bash
   aws eks update-kubeconfig --region <region> --name idp-cluster
   ```
3. `istioctl` matching the control-plane version (1.29.2).

## Apply order

```bash
cd istio-manifests

# 1. Namespaces
kubectl apply -f namespaces.yaml

# 2. The ingress gateways (grc ClusterIP + global NLB). Control plane already
#    exists (Terraform), so this only adds the gateway pods/Services.
istioctl install -f minimal-profile.yaml

# 3. Global edge: Gateway + VirtualService (routes /grc)
kubectl apply -k global-istio-gw/

# 4. grc team Gateway + VirtualService
kubectl apply -f domain-istio-gateway/grc/gateway-virtualservice.yaml
```

## Get the public NLB address

```bash
kubectl -n global-istio-ingress get svc global-istio-ingressgateway \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

## Test the path

`fraud-svc` in `grc-team` (port 6061) must exist for a 200; otherwise you'll get
a 503 from the gateway, which still proves routing works.

```bash
NLB=$(kubectl -n global-istio-ingress get svc global-istio-ingressgateway \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Host header must match the Gateway/VirtualService host.
curl -H "Host: finance.hellocloud.io" "http://$NLB/grc/audits"
```

Flow: `user -> NLB -> global-istio-gateway -> (rewrite /grc/audits -> /audits)
-> grc ingress gw -> grc VirtualService -> fraud-svc.grc-team:6061`.

## Teardown

```bash
kubectl delete -f domain-istio-gateway/grc/gateway-virtualservice.yaml
kubectl delete -k global-istio-gw/
istioctl uninstall -f minimal-profile.yaml      # removes the gateways
kubectl delete -f namespaces.yaml
```

> Delete the gateway Services **before** `terraform destroy` so the AWS cloud
> controller removes the NLB before the VPC is torn down.
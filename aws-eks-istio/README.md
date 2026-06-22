# Istio on AWS EKS (Terraform)

Stands up the AWS equivalent of the local kind + Cilium setup, so the Istio
project can run on managed Kubernetes.

## What this creates

| Layer | Resource |
|-------|----------|
| Network | VPC across 3 AZs, public + private subnets, single NAT gateway |
| Cluster | EKS managed control plane (`kubernetes_version`) |
| Compute | One EKS managed node group (private subnets) |
| Add-ons | CoreDNS, kube-proxy, **AWS VPC CNI** |
| Mesh control plane | `istio-base` + `istiod` via Helm |
| Gateways + routing | **Not** in Terraform — applied from [`istio-manifests/`](istio-manifests/) via istioctl + kubectl (mirrors `istio-gateway-cilium/`, grc path) |

### Differences from the local kind/Cilium setup
- **CNI is AWS VPC CNI, not Cilium.** Pods get real VPC IPs. There is no
  `cilium_host` router IP, no Cilium LB IPAM / L2 announcements, and no
  kube-proxy replacement.
- The `socketLB.hostNamespaceOnly` mTLS workaround **does not apply** — it was
  Cilium-specific. Istio mTLS works normally on VPC CNI.
- The external IP for the global gateway comes from an **AWS NLB**, replacing
  the MetalLB / Cilium LB IPAM role in `cluster-with-cilium/`.

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

Get the external gateway hostname (NLB DNS name):

```bash
kubectl -n global-istio-ingress get svc global-istio-ingressgateway \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

## Gateways + routing (after the cluster is up)

Terraform installs only the **control plane** (base + istiod). The gateways and
routing are applied from [`istio-manifests/`](istio-manifests/) — the AWS mirror
of `istio-gateway-cilium/`, trimmed to the **grc** path. See
[istio-manifests/README.md](istio-manifests/README.md) for full detail; the
short version:

```bash
aws eks update-kubeconfig --region <region> --name idp-cluster

cd istio-manifests
kubectl apply -f namespaces.yaml                                   # grc + global ns
istioctl install -f minimal-profile.yaml                           # grc + global gateways (NLB)
kubectl apply -k global-istio-gw/                                  # global edge: routes /grc
kubectl apply -f domain-istio-gateway/grc/gateway-virtualservice.yaml
```

## Destroy

```bash
terraform destroy
```

If the gateway's NLB was created by Kubernetes (not Terraform), delete the
gateway/services first so the cloud controller cleans up the NLB before the VPC
is torn down:

```bash
kubectl delete -k istio-manifests/global-istio-gw/ || true
istioctl uninstall -f istio-manifests/minimal-profile.yaml || true
terraform destroy
```

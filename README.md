# Two-Tier API Gateway on EKS

A Kubernetes-based API gateway solution implementing a two-tier architecture with Kong Gateway, Kong Ingress Controller, and the Kubernetes Gateway API standard.

## Overview

This project demonstrates a multi-tier API gateway architecture for banking-style services.

- **Global Gateway Tier**: Provides centralized ingress and path-based routing for API traffic.
- **Domain Gateway Tier**: Provides domain-specific gateways, routing, and isolation for business services.
- **Backend Service Tier**: Runs demo application chains for retail banking, payments, and GRC.

The architecture uses:

- **Kong Ingress Controller (KIC)** to reconcile Gateway API resources into Kong configuration.
- **Kubernetes Gateway API** for `GatewayClass`, `Gateway`, `HTTPRoute`, and `ReferenceGrant`.
- **Multi-namespace isolation** for gateway controllers and application domains.
- **Route 53** for public DNS records under `mini-apps.click`.
- **Terraform** for optional HTTPS automation with Let's Encrypt certificates.

## Architecture

Traffic can enter through either the domain-specific gateways or the optional global gateway layer.

Direct domain gateway access:

```text
Client
  -> retail-banking.mini-apps.click
  -> retail-banking Kong Gateway
  -> customer-profile-svc
  -> account-svc
  -> statement-svc
```

Two-tier global gateway flow:

```text
Client
  -> Global Kong Gateway
  -> global HTTPRoute
  -> domain Kong Gateway proxy
  -> domain HTTPRoute
  -> backend services
```

## Project Structure

```text
.
├── kong/                       # Global gateway tier
│   ├── 0-gatewayclass-global.yaml
│   ├── 1-kong-api-gateway-global.yaml
│   ├── 2-referencegrants.yaml
│   └── 3-global-httproute.yaml
├── apps/                       # Domain gateways and backend services
│   ├── retail-banking/
│   ├── payments/
│   └── grc/
├── for_https/                  # Terraform for HTTPS
│   ├── main.tf
│   ├── gateways_https.tf
│   ├── variables.tf
│   └── terraform.tfvars.example
└── setup.coffee                # Step-by-step deployment runbook
```

## Components

### Global Gateway Tier

Located in `kong/`, this tier provides centralized routing resources.

- `0-gatewayclass-global.yaml`: Defines `global-kong-gatewayclass`.
- `1-kong-api-gateway-global.yaml`: Creates `global-kong-api-gateway`.
- `2-referencegrants.yaml`: Allows global routes to reference downstream KIC proxy Services across namespaces.
- `3-global-httproute.yaml`: Routes requests by path prefix to the domain gateways.

The global route is designed for path-based routing:

- `/retail-banking` -> retail banking gateway proxy
- `/payments` -> payments gateway proxy
- `/grc` -> GRC gateway proxy

### Domain Gateway Tier

Located in `apps/<domain>/`, each domain has its own Gateway API resources and Kong controller name.

| Domain | Gateway namespace | GatewayClass | Public hostname |
| --- | --- | --- | --- |
| Retail Banking | `retail-banking-kic` | `retail-banking-kong-gatewayclass` | `retail-banking.mini-apps.click` |
| Payments | `payments-kic` | `payments-kong-gatewayclass` | `payments.mini-apps.click` |
| GRC | `grc-kic` | `grc-kong-gatewayclass` | `grc.mini-apps.click` |

### Backend Services

Each domain has a small fake-service chain for testing routing and upstream calls.

| Domain | Entry service | Downstream service chain |
| --- | --- | --- |
| Retail Banking | `customer-profile-svc` | `account-svc -> statement-svc` |
| Payments | `transfer-svc` | `payment-gateway-svc -> fx-svc` |
| GRC | `fraud-svc` | `audit-svc -> sanction-svc` |

## Key Features

- **Two-tier gateway design**: Optional global gateway in front of domain-specific gateways.
- **Domain isolation**: Separate namespaces and Kong controller names per business domain.
- **Gateway API standard**: Uses Kubernetes-native `GatewayClass`, `Gateway`, `HTTPRoute`, and `ReferenceGrant`.
- **Cross-namespace routing**: Uses `ReferenceGrant` where global routes reference downstream Services.
- **Route 53 integration**: Public hostnames route to Kong LoadBalancers.
- **HTTPS automation**: Terraform can issue Let's Encrypt certificates and configure HTTPS listeners.

## Kubernetes Resource Pattern

The project follows a simple file naming convention:

- `0-*`: GatewayClass definitions.
- `1-*`: Gateway instances.
- `2-*`: Cross-namespace grants or supporting resources.
- `3-*`: HTTPRoute traffic rules.
- Service files: backend Services, ServiceAccounts, and Deployments.

## Prerequisites

- Amazon EKS cluster.
- AWS CLI configured with profile `demo-microservices`.
- `eksctl`
- `kubectl`
- `helm`
- Gateway API CRDs installed.
- Kong Ingress Controller installed once per gateway domain.
- Route 53 public hosted zone for `mini-apps.click`.
- Terraform, only if enabling HTTPS.

## Installation

Use `setup.coffee` as the deployment runbook:

```bash
setup.coffee
```

High-level order:

1. Create or connect to the EKS cluster.
2. Install Gateway API CRDs.
3. Install Kong Ingress Controller releases for retail banking, payments, and GRC.
4. Apply domain GatewayClass and Gateway manifests.
5. Deploy backend Services and HTTPRoutes.
6. Optionally apply the global gateway resources in `kong/`.
7. Create Route 53 alias records for each domain hostname.
8. Test HTTP access.
9. Optionally enable HTTPS using Terraform in `for_https/`.

## Namespaces

Gateway namespaces:

- `global-kic`
- `retail-banking-kic`
- `payments-kic`
- `grc-kic`

Routing and application namespaces:

- `global-api-gateway-ns`
- `retail-banking`
- `payments`
- `grc`

## Usage

Test the direct domain gateways:

```bash
curl -i http://retail-banking.mini-apps.click/
curl -i http://payments.mini-apps.click/
curl -i http://grc.mini-apps.click/
```

If local DNS is stale, test with the Kong ELB and a Host header:

```bash
curl -i -H "Host: retail-banking.mini-apps.click" http://<retail-banking-kong-elb>/
curl -i -H "Host: payments.mini-apps.click" http://<payments-kong-elb>/
curl -i -H "Host: grc.mini-apps.click" http://<grc-kong-elb>/
```

## HTTPS

The `for_https/` folder contains Terraform that:

- Requests Let's Encrypt certificates with Route 53 DNS validation.
- Creates Kubernetes TLS Secrets in each `*-kic` namespace.
- Adds HTTPS listeners on port `443` to each domain Gateway.

Run:

```bash
cd for_https
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

Then test:

```bash
curl -i https://retail-banking.mini-apps.click/
curl -i https://payments.mini-apps.click/
curl -i https://grc.mini-apps.click/
```

## Troubleshooting

Check Gateway status:

```bash
kubectl get gateway -A
kubectl describe gateway -n retail-banking-kic retail-banking-kong-api-gateway
```

Check routes:

```bash
kubectl get httproute -A
kubectl describe httproute -n retail-banking customer-profile-httproute
```

Look for:

```text
Accepted=True
ResolvedRefs=True
Programmed=True
```

Check Kong proxy Services:

```bash
kubectl get svc -A | grep gateway-proxy
```

Check application Pods and Services:

```bash
kubectl get pods,svc -n retail-banking
kubectl get pods,svc -n payments
kubectl get pods,svc -n grc
```

Check Kong controller logs:

```bash
kubectl logs -n retail-banking-kic -l app.kubernetes.io/name=ingress-controller
kubectl logs -n payments-kic -l app.kubernetes.io/name=ingress-controller
kubectl logs -n grc-kic -l app.kubernetes.io/name=ingress-controller
```

## Safety Notes

Do not commit:

- AWS credentials
- kubeconfig files
- private keys
- `terraform.tfvars`
- Terraform state files
- `.terraform/`

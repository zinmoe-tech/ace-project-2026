# Kong API Gateway With ExternalName

This project demonstrates a multi-layer Kong API Gateway architecture on Kubernetes using the Gateway API. It models a banking platform where one global gateway receives public traffic and routes requests to domain-specific Kong gateways for Retail Banking, Payments, and GRC.

The main purpose of the project is to show how a central API entry point can delegate traffic to separate business-domain gateway layers without exposing every downstream gateway directly to clients.

## Interview Summary

I built a Kubernetes-based API gateway architecture using Kong Gateway and the Gateway API. The design has a global gateway in front, exposed through `mybank.mini-apps.click`, and three downstream domain gateways behind it.

The global gateway routes by path prefix:

- `/retail-banking` goes to the Retail Banking gateway.
- `/payments` goes to the Payments gateway.
- `/grc` goes to the GRC gateway.

Instead of routing directly to application services, the global gateway routes to Kubernetes `ExternalName` services. Each `ExternalName` service points to the internal proxy service of a downstream Kong gateway. The downstream Kong gateway then applies its own `HTTPRoute` and forwards the request to the correct application service.

This creates a clean separation between platform-level routing and domain-level routing.

## Architecture

```text
Client
  |
  v
mybank.mini-apps.click
  |
  v
Global Kong Gateway
  |
  v
Global HTTPRoute
  |
  +-- /retail-banking --> ExternalName --> Retail Banking Kong Gateway --> customer-profile-svc
  |
  +-- /payments -------> ExternalName --> Payments Kong Gateway -------> transfer-svc
  |
  +-- /grc ------------> ExternalName --> GRC Kong Gateway ------------> fraud-svc
```

## Main Traffic Flow

Example request:

```bash
curl http://mybank.mini-apps.click/payments
```

Flow:

```text
Client
  -> mybank.mini-apps.click/payments
  -> global-kong-api-gateway
  -> global-httproute
  -> payments-kic-gateway-proxy ExternalName service
  -> payments-kic-gateway-proxy.payments-kic.svc.cluster.local
  -> payments-kong-api-gateway
  -> transfer-httproute
  -> transfer-svc
  -> payment-gateway-svc
  -> fx-svc
```

The global route also rewrites the request before sending it downstream:

```text
Original host: mybank.mini-apps.click
Original path: /payments

Rewritten host: payments.mini-apps.click
Rewritten path: /
```

This is important because the downstream Payments `HTTPRoute` expects the hostname `payments.mini-apps.click` and path `/`.

## Why ExternalName Is Used

The global `HTTPRoute` backend must reference a Kubernetes `Service` in its routing namespace. The downstream Kong proxy services are in different KIC namespaces, so this project creates local `ExternalName` aliases in `global-api-gateway-ns`.

Example:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: payments-kic-gateway-proxy
  namespace: global-api-gateway-ns
spec:
  type: ExternalName
  externalName: payments-kic-gateway-proxy.payments-kic.svc.cluster.local
```

This means:

```text
payments-kic-gateway-proxy.global-api-gateway-ns
  -> payments-kic-gateway-proxy.payments-kic.svc.cluster.local
```

The traffic stays inside the Kubernetes cluster and reaches the downstream Kong proxy service through Kubernetes DNS.

## Namespaces

Platform and gateway namespaces:

| Namespace | Purpose |
| --- | --- |
| `global-kic` | Contains the global Kong Gateway |
| `global-api-gateway-ns` | Contains the global `HTTPRoute` and `ExternalName` services |
| `retail-banking-kic` | Contains the Retail Banking Kong Gateway |
| `payments-kic` | Contains the Payments Kong Gateway |
| `grc-kic` | Contains the GRC Kong Gateway |

Application team namespaces:

| Namespace | Purpose |
| --- | --- |
| `retail-banking-team` | Retail Banking application services and routes |
| `payments-team` | Payments application services and routes |
| `grc-team` | GRC application services and routes |

This separation is useful in interviews because it shows platform ownership and application-team ownership as separate concerns.

## Application Service Chains

Retail Banking:

```text
customer-profile-svc
  -> account-svc
  -> statement-svc
```

Payments:

```text
transfer-svc
  -> payment-gateway-svc
  -> fx-svc
```

GRC:

```text
fraud-svc
  -> audit-svc
  -> sanction-svc
```

## Important Files

| File | Description |
| --- | --- |
| `0-gatewayclass-global.yaml` | Defines the global `GatewayClass` |
| `1-kong-api-gateway-global.yaml` | Creates the global KIC namespace, global Gateway, and global route namespace |
| `2-downstream-proxy-services.yaml` | Creates `ExternalName` services that point to downstream Kong proxy services |
| `3-global-httproute.yaml` | Routes public paths from `mybank.mini-apps.click` to the downstream gateways |
| `apps/retail-banking/*` | Retail Banking Gateway API and service manifests |
| `apps/payments/*` | Payments Gateway API and service manifests |
| `apps/grc/*` | GRC Gateway API and service manifests |
| `for_https/*` | Terraform configuration for TLS certificates and HTTPS listeners |

## Deployment Order

Apply the global gateway layer:

```bash
kubectl apply -f 0-gatewayclass-global.yaml
kubectl apply -f 1-kong-api-gateway-global.yaml
kubectl apply -f 2-downstream-proxy-services.yaml
kubectl apply -f 3-global-httproute.yaml
```

Apply each domain layer:

```bash
kubectl apply -f apps/retail-banking/
kubectl apply -f apps/payments/
kubectl apply -f apps/grc/
```

Check the gateways and routes:

```bash
kubectl get gateway -A
kubectl get httproute -A
kubectl get svc -A
```

## Test Commands

After DNS for `mybank.mini-apps.click` points to the global Kong load balancer:

```bash
curl -i http://mybank.mini-apps.click/retail-banking
curl -i http://mybank.mini-apps.click/payments
curl -i http://mybank.mini-apps.click/grc
```

Expected behavior:

- `/retail-banking` returns a response from the Retail Banking service chain.
- `/payments` returns a response from the Payments service chain.
- `/grc` returns a response from the GRC service chain.

## HTTPS

The `for_https` folder contains Terraform code to create Let's Encrypt certificates through Route 53 DNS validation, store them as Kubernetes TLS secrets, and update downstream Gateways with HTTPS listeners.

The HTTPS helper currently focuses on downstream domain hostnames:

- `retail-banking.mini-apps.click`
- `payments.mini-apps.click`
- `grc.mini-apps.click`

The global hostname `mybank.mini-apps.click` can be added in the same pattern if HTTPS is required for the global gateway.

## Interview Talking Points

- I used Kubernetes Gateway API resources instead of older Ingress resources.
- I separated the global gateway layer from business-domain gateways.
- I used `HTTPRoute` path matching and `URLRewrite` to forward requests cleanly.
- I used `ExternalName` services as DNS aliases to downstream Kong proxy services.
- I separated KIC namespaces from application team namespaces.
- I kept routing ownership flexible: the platform team can own the global gateway, while app teams own domain routes and services.
- I included Terraform support for certificate automation with Let's Encrypt and Route 53.

## Key Design Benefit

The global gateway gives clients one stable banking API entry point, while each domain team can manage its own gateway and routing rules behind it. This improves separation of responsibility, keeps the architecture scalable, and makes it easier to add new domains later.

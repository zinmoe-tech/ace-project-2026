# Global Istio Gateway

The single **Istio-native external edge** for the platform. All public traffic
enters here, and this is where **TLS termination** is configured.

```text
user
  -> global-istio-gateway          (edge; terminates TLS)
  -> global-routes VirtualService  (rewrites public path -> internal path)
  -> team Istio ingress gateway    (retail-banking / payments / grc, ClusterIP)
  -> team Gateway / VirtualService
  -> microservice
```

## Pieces

| File | Resource | Purpose |
|------|----------|---------|
| `00-namespace.yaml` | Namespace `global-istio-ingress` | hosts the edge gateway pod |
| `01-global-gateway.yaml` | `Gateway` | listener on `finance.hellocloud.io` (HTTP :80 today; TLS block ready to uncomment) |
| `02-global-virtualservice.yaml` | `VirtualService` | maps public paths to each team's ingress gateway Service |

The gateway **pod** itself (`global-istio-ingressgateway`, type `LoadBalancer`)
is declared with the other gateways in `../istio/minimal-profile.yaml`.

## Public path map

| Public path | Rewritten to | Team ingress gateway |
|-------------|--------------|----------------------|
| `/retail-banking/customer-profile-svc` | `/accounts` | `retail-banking-istio-ingressgateway` |
| `/payments/transactions` | `/transactions` | `payments-istio-ingressgateway` |
| `/grc/audits` | `/audits` | `grc-istio-ingressgateway` |

## Apply

The gateway pod comes from the operator (re-run after editing minimal-profile):

```bash
istioctl install -f ../istio/minimal-profile.yaml
```

Then the routing layer:

```bash
kubectl apply -k .
```

Verify:

```bash
kubectl get gateway -n global-istio-ingress
kubectl get vs -n global-istio-ingress
kubectl get svc -n global-istio-ingress global-istio-ingressgateway   # note EXTERNAL-IP
```

## TLS termination PoC

`01-global-gateway.yaml` keeps the HTTPS server block commented out. To enable
**SIMPLE** mode (one-way TLS):

```bash
# 1. mint a self-signed cert for the host
openssl req -x509 -newkey rsa:2048 -nodes -days 365 \
  -keyout finance.key -out finance.crt \
  -subj "/CN=finance.hellocloud.io" \
  -addext "subjectAltName=DNS:finance.hellocloud.io"

# 2. load it as a TLS secret IN THE GATEWAY POD'S NAMESPACE
kubectl -n global-istio-ingress create secret tls finance-tls \
  --cert=finance.crt --key=finance.key

# 3. uncomment the :443 HTTPS server in 01-global-gateway.yaml, then re-apply
kubectl apply -k .

# 4. test
curl -vk https://finance.hellocloud.io/grc/audits \
  --resolve finance.hellocloud.io:443:<EXTERNAL-IP>
```

For **MUTUAL** mode, switch `mode: SIMPLE` -> `mode: MUTUAL`, add
`caCertificates` (or a `credentialName` carrying the CA), and the gateway will
then require a client certificate during the handshake.

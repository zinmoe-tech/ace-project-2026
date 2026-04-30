# Istio mTLS

This directory contains the Istio resources that encrypt every in-cluster hop
with mutual TLS while leaving the public edge (Global Kong) reachable over
normal HTTPS.

## Protected traffic

| Hop | Caller namespace | Destination namespace |
|---|---|---|
| Global Kong → Retail Banking KIC | `global-kic` | `retail-banking-kic` |
| Global Kong → Payments KIC | `global-kic` | `payments-kic` |
| Global Kong → GRC KIC | `global-kic` | `grc-kic` |
| Retail Banking KIC → customer-profile | `retail-banking-kic` | `retail-banking-team` |
| customer-profile → account → statement | `retail-banking-team` | `retail-banking-team` |
| Payments KIC → transfer | `payments-kic` | `payments-team` |
| transfer → payment-gateway → fx | `payments-team` | `payments-team` |
| GRC KIC → fraud | `grc-kic` | `grc-team` |
| fraud → audit → sanction | `grc-team` | `grc-team` |

`global-api-gateway-ns` contains only `ExternalName` services and `HTTPRoute`
objects — no pods — so it is not part of the sidecar mesh.

`global-kic` receives traffic from public HTTPS clients that do not carry Istio
certificates, so it is intentionally left at mesh-wide PERMISSIVE on the inbound
side. All traffic *leaving* `global-kic` uses Istio mTLS via the DestinationRules.

## Files

| File | Purpose |
|---|---|
| `00-mesh-namespaces.yaml` | Namespace definitions with `istio-injection: enabled` (alternative to the labels already in the gateway manifests) |
| `00-mtls-permissive.yaml` | Mesh-wide PERMISSIVE PeerAuthentication — apply first to allow sidecars to come up before enforcing |
| `05-destinationrules-istio-mutual.yaml` | DestinationRules for every outbound hop — tell each caller's Envoy to originate ISTIO_MUTUAL TLS |
| `10-mtls-strict-internal.yaml` | Namespace-scoped STRICT PeerAuthentication for all internal namespaces — apply after sidecars are confirmed |

## Rollout

### Phase 1 — PERMISSIVE + DestinationRules

```bash
kubectl apply -f istio/00-mtls-permissive.yaml
kubectl apply -f istio/05-destinationrules-istio-mutual.yaml
```

Verify every pod in the mesh namespaces has an `istio-proxy` container:

```bash
for ns in global-kic retail-banking-kic retail-banking-team payments-kic payments-team grc-kic grc-team; do
  echo "=== $ns ===";
  kubectl get pods -n "$ns" -o jsonpath='{range .items[*]}{.metadata.name}{"  "}{.spec.containers[*].name}{"\n"}{end}';
done
```

Confirm all routes work before proceeding.

### Phase 2 — STRICT

```bash
kubectl apply -f istio/10-mtls-strict-internal.yaml
```

### Roll back

```bash
kubectl delete -f istio/10-mtls-strict-internal.yaml --ignore-not-found
kubectl apply -f istio/00-mtls-permissive.yaml
kubectl apply -f istio/05-destinationrules-istio-mutual.yaml
```

## Verify mTLS is active

Check active PeerAuthentication policies:

```bash
kubectl get peerauthentication -A
```

Check DestinationRules:

```bash
kubectl get destinationrule -A
```

Confirm a connection is mTLS by inspecting the Envoy stats from inside a pod:

```bash
kubectl exec -n retail-banking-team deploy/customer-profile-svc \
  -c istio-proxy -- pilot-agent request GET stats | grep ssl.handshake
```

A non-zero `ssl.handshake` counter confirms TLS sessions are being established.

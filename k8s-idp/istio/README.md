# Team Istio Routes

These examples match the lower part of the diagram.

Each team has:

- one Istio `Gateway` that selects that team's ingress gateway pod
- one Istio `VirtualService` that forwards the public path to the team service

Apply after:

1. `istio-gateway/minimal-profile.yaml` has installed Istiod and the three ingress gateways
2. the application Services exist in `retail-banking`, `payments`, and `grc`

```bash
kubectl apply -k istio-gateway/team-istio-routes
```


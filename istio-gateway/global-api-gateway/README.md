# Global API Gateway Layer

This folder matches the top and middle of the target diagram:

- one Kong/KIC global API gateway
- one shared `HTTPRoute` with public paths
- one backend reference per team ingress gateway

Traffic flow:

```text
user
  -> Kong global gateway
  -> global HTTPRoute
  -> team Istio ingress gateway Service
  -> team Istio Gateway / VirtualService
  -> microservice
```

Apply after Kong Ingress Controller and the Gateway API CRDs are installed:

```bash
kubectl apply -k istio-gateway/global-api-gateway
```

Check the global gateway IP:

```bash
kubectl get gateway -n global-kic
kubectl get svc -n global-kic
```

The example hostname is `finance.hellocloud.io`. Change it in
`03-global-httproute.yaml` if your hostname is different.


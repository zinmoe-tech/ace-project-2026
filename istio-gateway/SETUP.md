# Kong Global Gateway + Istio Team Gateways Setup

This setup matches the `istio-gateway/` manifests.

Architecture:

```text
User
  -> global Kong Gateway
  -> global HTTPRoute
  -> team Istio ingress gateway
  -> team Istio VirtualService
  -> application Service
```

This project uses one Kong Ingress Controller only:

```text
global-kic
```

The team gateways are Istio ingress gateways created by:

```text
istio-gateway/minimal-profile.yaml
```

## 1. Install Gateway API CRDs

```bash
kubectl apply --server-side \
  -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.1/standard-install.yaml
```

Verify:

```bash
kubectl api-resources --api-group=gateway.networking.k8s.io
```

## 2. Install Kong Ingress Controller

Add the Kong Helm repo:

```bash
helm repo add kong https://charts.konghq.com
helm repo update
```

Install the global Kong controller:

```bash
helm upgrade --install global-kic kong/ingress \
  --namespace global-kic --create-namespace \
  --set gateway.proxy.type=LoadBalancer \
  --set controller.ingressController.env.gateway_api_controller_name=konghq.com/global-kong-gateway-controller
```

The controller name above must match:

```yaml
# istio-gateway/global-api-gateway/01-gatewayclass.yaml
spec:
  controllerName: konghq.com/global-kong-gateway-controller
```

Verify:

```bash
kubectl get pods -n global-kic
kubectl get svc -n global-kic
```

## 3. Install Istio Control Plane And Team Ingress Gateways

This creates:

```text
istiod
retail-banking-istio-ingressgateway
payments-istio-ingressgateway
grc-istio-ingressgateway
```

Run:

```bash
istioctl install -f istio-gateway/minimal-profile.yaml -y
```

Verify:

```bash
kubectl get pods -n istio-system
kubectl get svc -n retail-banking-team retail-banking-istio-ingressgateway
kubectl get svc -n payments-team payments-istio-ingressgateway
kubectl get svc -n grc-team grc-istio-ingressgateway
```

## 4. Deploy Application Services

```bash
kubectl apply -f istio-gateway/apps/retail-banking/
kubectl apply -f istio-gateway/apps/payments/
kubectl apply -f istio-gateway/apps/grc/
```

Verify:

```bash
kubectl get pods -n retail-banking-team
kubectl get pods -n payments-team
kubectl get pods -n grc-team
```

## 5. Deploy Global Kong Gateway Routes

```bash
kubectl apply -f istio-gateway/global-api-gateway
```

This creates:

```text
GatewayClass/global-kong-gatewayclass
Gateway/global-kic/global-kong-globalgateway
HTTPRoute/global-api-gateway-ns/global-httproute
ReferenceGrants in each team namespace
```

The global HTTPRoute rewrites paths:

```text
/retail-banking/customer-profile-svc -> /accounts
/payments/transactions   -> /transactions
/grc/audits              -> /audits
```

Verify:

```bash
kubectl get gatewayclass
kubectl get gateway -n global-kic
kubectl get httproute -n global-api-gateway-ns
kubectl get referencegrant -n retail-banking-team
kubectl get referencegrant -n payments-team
kubectl get referencegrant -n grc-team
```

## 6. Deploy Team Istio Routes

```bash
kubectl apply -k istio-gateway/team-istio-routes
```

This creates one Istio Gateway and VirtualService per team.

Verify:

```bash
kubectl get gateway.networking.istio.io -A
kubectl get virtualservice -A
```

## 7. Test

Get the Kong external address:

```bash
kubectl get svc -n global-kic
```

Then test with your load balancer IP or DNS name:

```bash
curl -H "Host: finance.hellocloud.io" http://<GLOBAL_KONG_LB>/retail-banking/customer-profile-svc
curl -H "Host: finance.hellocloud.io" http://<GLOBAL_KONG_LB>/payments/transactions
curl -H "Host: finance.hellocloud.io" http://<GLOBAL_KONG_LB>/grc/audits
```

## Important Notes

- Do not install `retail-banking-kic`, `payments-kic`, or `grc-kic` for this setup.
- Those are for the separate Kong-to-Kong ExternalName design.
- This setup uses Kong only at the global edge and Istio ingress gateways per team.
- If `GatewayClass` is not accepted, check that Kong was installed with the same `gateway_api_controller_name`.

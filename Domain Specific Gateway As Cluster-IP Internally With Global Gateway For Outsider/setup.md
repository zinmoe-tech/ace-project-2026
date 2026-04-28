# Setup Guide

This guide deploys a Global Kong Gateway with internal domain Kong Gateways and enables Istio mTLS for gateway-to-gateway and service-to-service traffic.

The recommended rollout is:

1. Install Istio and enable sidecar injection.
2. Deploy Kong and the sample services.
3. Apply mTLS `PERMISSIVE` mode.
4. Verify all Kong and app pods have sidecars and traffic works.
5. Switch internal namespaces to mTLS `STRICT` mode.

The public client to `mybank.mini-apps.click` is not Istio mTLS. It should use normal HTTPS/TLS at the edge. Istio mTLS is for in-cluster workload-to-workload traffic.

## 1. Prerequisites

Make sure these are installed and configured:

- AWS CLI
- eksctl
- kubectl
- helm
- istioctl
- An AWS profile that can create and manage EKS resources
- DNS access for `mini-apps.click`

Replace `aws-profile` in the commands below with your real AWS CLI profile name.

## 2. Create Or Connect To The EKS Cluster

Create the EKS cluster:

```bash
eksctl create cluster \
  --name demo-eks-cluster \
  --region ap-southeast-1 \
  --version 1.34 \
  --instance-types t3.medium \
  --nodes-min 3 \
  --profile aws-profile
```

Update your local kubeconfig:

```bash
aws eks update-kubeconfig \
  --name demo-eks-cluster \
  --region ap-southeast-1 \
  --profile aws-profile
```

Verify the cluster connection:

```bash
kubectl get nodes
kubectl get ns

eksctl get cluster \
  --region ap-southeast-1 \
  --profile aws-profile
```

## 3. Install Istio

Install Istio with the default profile:

```bash
istioctl install --set profile=default -y
kubectl get pods -n istio-system
```

Apply the namespace manifests before installing Kong:

```bash
kubectl apply -f kong-global-gateway/00-global-kic-namespace.yaml
kubectl apply -f kong-global-gateway/00-global-api-gateway-namespace.yaml
kubectl apply -f apps/grc/03-grc-kic-ns.yaml
kubectl apply -f apps/grc/04-grc-ns.yaml
kubectl apply -f apps/payments/03-payments-kic-ns.yaml
kubectl apply -f apps/payments/04-payments-ns.yaml
kubectl apply -f apps/retail-banking/03-retail-banking-kic-ns.yaml
kubectl apply -f apps/retail-banking/04-retail-banking-ns.yaml
```

Label only workload namespaces for Istio sidecar injection:

```bash
for ns in \
  global-kic \
  grc-kic \
  grc-team \
  payments-kic \
  payments-team \
  retail-banking-kic \
  retail-banking-team
do
  kubectl label namespace "$ns" istio-injection=enabled --overwrite
done

kubectl label namespace global-api-gateway-ns istio-injection- --overwrite
```

`global-api-gateway-ns` is intentionally not sidecar-injected. It only contains `HTTPRoute` and `ExternalName` Service resources, not pods.

## 4. Install Kong Ingress Controller Instances

Add the Kong Helm repository:

```bash
helm repo add kong https://charts.konghq.com
helm repo update
```

Install Kong Ingress Controller for the Global Gateway:

```bash
helm upgrade --install global-kic kong/ingress \
  --namespace global-kic \
  --set controller.ingressController.env.gateway_api_controller_name=konghq.com/global-kong-gateway-controller
```

Install Kong Ingress Controller for Retail Banking:

```bash
helm upgrade --install retail-banking-kic kong/ingress \
  --namespace retail-banking-kic \
  --set controller.ingressController.env.gateway_api_controller_name=konghq.com/retail-banking-kong-gateway-controller \
  --set gateway.proxy.type=ClusterIP
```

Install Kong Ingress Controller for Payments:

```bash
helm upgrade --install payments-kic kong/ingress \
  --namespace payments-kic \
  --set controller.ingressController.env.gateway_api_controller_name=konghq.com/payments-kong-gateway-controller \
  --set gateway.proxy.type=ClusterIP
```

Install Kong Ingress Controller for GRC:

```bash
helm upgrade --install grc-kic kong/ingress \
  --namespace grc-kic \
  --set controller.ingressController.env.gateway_api_controller_name=konghq.com/grc-kong-gateway-controller \
  --set gateway.proxy.type=ClusterIP
```

Verify Kong pods and proxy services:

```bash
kubectl get pods -A | grep kic
kubectl get svc -A | grep gateway-proxy
```

Each Kong pod should include an `istio-proxy` sidecar:

```bash
kubectl get pods -n global-kic -o jsonpath='{range .items[*]}{.metadata.name}{" containers="}{.spec.containers[*].name}{"\n"}{end}'
kubectl get pods -n grc-kic -o jsonpath='{range .items[*]}{.metadata.name}{" containers="}{.spec.containers[*].name}{"\n"}{end}'
kubectl get pods -n payments-kic -o jsonpath='{range .items[*]}{.metadata.name}{" containers="}{.spec.containers[*].name}{"\n"}{end}'
kubectl get pods -n retail-banking-kic -o jsonpath='{range .items[*]}{.metadata.name}{" containers="}{.spec.containers[*].name}{"\n"}{end}'
```

If any Kong pod does not have an `istio-proxy` container, restart the release after confirming the namespace label exists:

```bash
kubectl rollout restart deployment -n global-kic
kubectl rollout restart deployment -n grc-kic
kubectl rollout restart deployment -n payments-kic
kubectl rollout restart deployment -n retail-banking-kic
```

## 5. Apply Gateway And Application Manifests

From this project directory, apply the global gateway:

```bash
kubectl apply -f kong-global-gateway/0-gatewayclass-global.yaml
kubectl apply -f kong-global-gateway/1-kong-api-gateway-global.yaml
kubectl apply -f kong-global-gateway/2-downstream-proxy-services.yaml
kubectl apply -f kong-global-gateway/3-global-httproute.yaml
```

Apply the GRC domain:

```bash
kubectl apply -f apps/grc/00-grc-gatewayclass.yaml
kubectl apply -f apps/grc/01-grc-kong-api-gateway.yaml
kubectl apply -f apps/grc/fraud.yaml
kubectl apply -f apps/grc/audit.yaml
kubectl apply -f apps/grc/sanction.yaml
kubectl apply -f apps/grc/02-fraud-httproute.yaml
```

Apply the Payments domain:

```bash
kubectl apply -f apps/payments/00-payments-gatewayclass.yaml
kubectl apply -f apps/payments/01-payments-kong-api-gateway.yaml
kubectl apply -f apps/payments/transfer-svc.yaml
kubectl apply -f apps/payments/payment-gateway.yaml
kubectl apply -f apps/payments/fx-svc.yaml
kubectl apply -f apps/payments/02-transfer-httproute.yaml
```

Apply the Retail Banking domain:

```bash
kubectl apply -f apps/retail-banking/00-retail-banking-gatewayclass.yaml
kubectl apply -f apps/retail-banking/01-retail-banking-kong-api-gateway.yaml
kubectl apply -f apps/retail-banking/customer-profile-service.yaml
kubectl apply -f apps/retail-banking/account-service.yaml
kubectl apply -f apps/retail-banking/statement-service.yaml
kubectl apply -f apps/retail-banking/02-customer-profile-httproute.yaml
```

Verify the application pods also have an `istio-proxy` sidecar:

```bash
kubectl get pods -n grc-team -o jsonpath='{range .items[*]}{.metadata.name}{" containers="}{.spec.containers[*].name}{"\n"}{end}'
kubectl get pods -n payments-team -o jsonpath='{range .items[*]}{.metadata.name}{" containers="}{.spec.containers[*].name}{"\n"}{end}'
kubectl get pods -n retail-banking-team -o jsonpath='{range .items[*]}{.metadata.name}{" containers="}{.spec.containers[*].name}{"\n"}{end}'
```

## 6. Enable mTLS PERMISSIVE Mode

Apply PERMISSIVE mode first. This allows both plaintext and mTLS while you confirm every workload is sidecar-injected.

```bash
kubectl apply -f istio/00-mtls-permissive.yaml
kubectl apply -f istio/05-destinationrules-istio-mutual.yaml
```

Test the public route:

```bash
GLOBAL_LB=$(kubectl get svc -n global-kic global-kic-gateway-proxy -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

curl -H "Host: mybank.mini-apps.click" "http://${GLOBAL_LB}/grc"
curl -H "Host: mybank.mini-apps.click" "http://${GLOBAL_LB}/payments"
curl -H "Host: mybank.mini-apps.click" "http://${GLOBAL_LB}/retail-banking"
```

Point DNS for `mybank.mini-apps.click` to the Global Kong load balancer when you are ready:

```bash
echo "$GLOBAL_LB"
```

## 7. Switch Internal Traffic To mTLS STRICT Mode

After all Kong and application pods show an `istio-proxy` container and the routes work in PERMISSIVE mode, enforce STRICT mTLS for the internal namespaces:

```bash
kubectl apply -f istio/10-mtls-strict-internal.yaml
```

Validate again:

```bash
curl -H "Host: mybank.mini-apps.click" "http://${GLOBAL_LB}/grc"
curl -H "Host: mybank.mini-apps.click" "http://${GLOBAL_LB}/payments"
curl -H "Host: mybank.mini-apps.click" "http://${GLOBAL_LB}/retail-banking"
```

Expected result:

- Public client to Global Kong: normal HTTP/HTTPS edge traffic.
- Global Kong to domain Kong gateways: Istio mTLS.
- Domain Kong gateways to backend services: Istio mTLS.
- Service-to-service calls inside each domain: Istio mTLS.
- Plaintext direct calls to STRICT internal workloads: blocked.

## 8. Roll Back STRICT Mode

If STRICT mode exposes a workload without a sidecar, return to PERMISSIVE mode:

```bash
kubectl delete -f istio/10-mtls-strict-internal.yaml --ignore-not-found
kubectl apply -f istio/00-mtls-permissive.yaml
kubectl apply -f istio/05-destinationrules-istio-mutual.yaml
```

Then fix sidecar injection and retry STRICT mode.

# Setup Guide

This guide explains how to deploy and test the Kong API Gateway with `ExternalName` services step by step.

################################################################################
# 1. Prerequisites
################################################################################

Make sure these are already installed and configured:

- AWS CLI.
- `eksctl`.
- `kubectl`.
- `helm`.
- `istioctl`.
- An AWS profile that can create and manage EKS resources.
- DNS access for `mini-apps.click`.

################################################################################
# 2. Create or connect to the EKS cluster
################################################################################

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
```

Confirm the EKS cluster exists:

```bash
eksctl get cluster \
  --region ap-southeast-1 \
  --profile aws-profile
```

Replace `aws-profile` with your real AWS CLI profile name.

################################################################################
# 3. Install Gateway API CRDs
################################################################################

Install the standard Gateway API CRDs:

```bash
kubectl apply --server-side \
  -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.1/standard-install.yaml
```

Verify the Gateway API resources:

```bash
kubectl api-resources --api-group=gateway.networking.k8s.io
```

################################################################################
# 4. Install Istio and prepare mesh namespaces
################################################################################

Install Istio before creating the Kong and application pods. This section
covers downloading istioctl, installing the Istio control plane on EKS, and
labeling namespaces for sidecar injection.

## 4a. Install istioctl

Download and install the istioctl binary. Version 1.22 is tested with
Kubernetes 1.28–1.34.

```bash
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.22.0 sh -
```

Move the binary to a directory on your PATH:

```bash
sudo mv istio-1.22.0/bin/istioctl /usr/local/bin/
rm -rf istio-1.22.0
```

Verify the installation:

```bash
istioctl version --remote=false
```

## 4b. Pre-flight check for EKS

Validate that the cluster meets Istio requirements before installing:

```bash
istioctl x precheck
```

All checks must pass. Common EKS-specific issues and fixes:

- **CNI**: EKS uses `amazon-vpc-cni`, which Istio supports natively. No extra
  action needed.
- **Node count**: At least 3 nodes are required to schedule istiod with its
  default anti-affinity. The cluster is created with `--nodes-min 3` so this
  is already satisfied.
- **API server**: Make sure `kubectl get nodes` shows all nodes in `Ready`
  state before proceeding.

## 4c. Install Istio on EKS

Install Istio using the `default` profile. This deploys the `istiod` control
plane and an `istio-ingressgateway` LoadBalancer. The ingress gateway is not
used by this project (Kong handles all public ingress), but the `default`
profile is the safest baseline for production use.

```bash
istioctl install --set profile=default -y
```

Wait for `istiod` and the ingress gateway to be ready:

```bash
kubectl rollout status deployment/istiod -n istio-system
kubectl rollout status deployment/istio-ingressgateway -n istio-system
kubectl get pods -n istio-system
```

Expected output — all pods should be `Running` and `READY 1/1`:

```text
NAME                                    READY   STATUS    RESTARTS   AGE
istio-ingressgateway-xxxxxxxxx-xxxxx    1/1     Running   0          2m
istiod-xxxxxxxxx-xxxxx                  1/1     Running   0          2m
```

Verify the Istio control plane version matches what was installed:

```bash
istioctl version
```

## 4d. Label mesh namespaces and enable sidecar injection

Sidecar injection is controlled by the `istio-injection: enabled` label on
each namespace. Apply the namespace manifests now so that every Kong and
application pod created in later steps automatically receives an Envoy
sidecar:

```bash
kubectl apply -f istio/00-mesh-namespaces.yaml
```

This creates (or patches) the following namespaces with the injection label:

```text
global-kic
retail-banking-kic
retail-banking-team
payments-kic
payments-team
grc-kic
grc-team
```

Confirm the label is present on each namespace:

```bash
kubectl get namespace -L istio-injection | grep enabled
```

All seven namespaces listed above must appear in the output.

The `global-api-gateway-ns` namespace has no pods (only `ExternalName` services
and `HTTPRoute` objects) and is intentionally not labeled for injection.

## 4e. Apply namespace manifests for Kong and applications

These manifests define the namespaces referenced by the Kong Helm installs
and application deployments in later steps. Applying them now (before Helm
installs) ensures every pod gets an Envoy sidecar from the moment it starts:

```bash
kubectl apply -f 1-kong-api-gateway-global.yaml
kubectl apply -f apps/retail-banking/01-retail-banking-kong-api-gateway.yaml
kubectl apply -f apps/retail-banking/customer-profile-service.yaml
kubectl apply -f apps/payments/01-payments-kong-api-gateway.yaml
kubectl apply -f apps/payments/payments-ns.yaml
kubectl apply -f apps/grc/01-grc-kong-api-gateway.yaml
kubectl apply -f apps/grc/grc-ns.yaml
```

################################################################################
# 5. Install Kong Ingress Controller instances
################################################################################

Add the Kong Helm repository:

```bash
helm repo add kong https://charts.konghq.com
helm repo update
```

Install Kong Ingress Controller for the Global Gateway:

```bash
helm install global-kic kong/ingress \
  --namespace global-kic \
  --create-namespace \
  --set controller.ingressController.env.gateway_api_controller_name=konghq.com/global-kong-gateway-controller
```

Install Kong Ingress Controller for Retail Banking:

```bash
helm install retail-banking-kic kong/ingress \
  --namespace retail-banking-kic \
  --create-namespace \
  --set controller.ingressController.env.gateway_api_controller_name=konghq.com/retail-banking-kong-gateway-controller
```

Install Kong Ingress Controller for Payments:

```bash
helm install payments-kic kong/ingress \
  --namespace payments-kic \
  --create-namespace \
  --set controller.ingressController.env.gateway_api_controller_name=konghq.com/payments-kong-gateway-controller
```

Install Kong Ingress Controller for GRC:

```bash
helm install grc-kic kong/ingress \
  --namespace grc-kic \
  --create-namespace \
  --set controller.ingressController.env.gateway_api_controller_name=konghq.com/grc-kong-gateway-controller
```

Verify Kong pods and proxy services:

```bash
kubectl get pods -A | grep kic
kubectl get svc -A | grep gateway-proxy
```

The downstream proxy services shown here are the real services targeted by the `ExternalName` services in `3-downstream-proxy-services.yaml`.

################################################################################
# 6. Deploy the global gateway layer
################################################################################

Apply the global GatewayClass:

```bash
kubectl apply -f 0-gatewayclass-global.yaml
```

Apply the global Kong Gateway namespace, Gateway, and route namespace:

```bash
kubectl apply -f 1-kong-api-gateway-global.yaml
```

Apply the `ExternalName` services. These services point the global route to each downstream Kong proxy service:

```bash
kubectl apply -f 3-downstream-proxy-services.yaml
```

Apply the global HTTPRoute:

```bash
kubectl apply -f 2-global-httproute.yaml
```

Verify:

```bash
kubectl get gatewayclass
kubectl get gateway -n global-kic
kubectl get httproute -n global-api-gateway-ns
kubectl get svc -n global-api-gateway-ns
```

################################################################################
# 7. Deploy Retail Banking
################################################################################

Apply the Retail Banking GatewayClass and Gateway:

```bash
kubectl apply -f apps/retail-banking/00-retail-banking-gatewayclass.yaml
kubectl apply -f apps/retail-banking/01-retail-banking-kong-api-gateway.yaml
```

Apply the Retail Banking application services:

```bash
kubectl apply -f apps/retail-banking/customer-profile-service.yaml
kubectl apply -f apps/retail-banking/account-service.yaml
kubectl apply -f apps/retail-banking/statement-service.yaml
```

Apply the Retail Banking HTTPRoute:

```bash
kubectl apply -f apps/retail-banking/02-customer-profile-httproute.yaml
```

Verify:

```bash
kubectl get gateway -n retail-banking-kic
kubectl get httproute -n retail-banking-team
kubectl get pods,svc -n retail-banking-team
```

################################################################################
# 8. Deploy Payments
################################################################################

Apply the Payments application namespace:

```bash
kubectl apply -f apps/payments/payments-ns.yaml
```

Apply the Payments GatewayClass and Gateway:

```bash
kubectl apply -f apps/payments/00-payments-gatewayclass.yaml
kubectl apply -f apps/payments/01-payments-kong-api-gateway.yaml
```

Apply the Payments application services:

```bash
kubectl apply -f apps/payments/transfer-svc.yaml
kubectl apply -f apps/payments/payment-gateway.yaml
kubectl apply -f apps/payments/fx-svc.yaml
```

Apply the Payments HTTPRoute:

```bash
kubectl apply -f apps/payments/02-transfer-httproute.yaml
```

Verify:

```bash
kubectl get gateway -n payments-kic
kubectl get httproute -n payments-team
kubectl get pods,svc -n payments-team
```

################################################################################
# 9. Deploy GRC
################################################################################

Apply the GRC application namespace:

```bash
kubectl apply -f apps/grc/grc-ns.yaml
```

Apply the GRC GatewayClass and Gateway:

```bash
kubectl apply -f apps/grc/00-grc-gatewayclass.yaml
kubectl apply -f apps/grc/01-grc-kong-api-gateway.yaml
```

Apply the GRC application services:

```bash
kubectl apply -f apps/grc/fraud.yaml
kubectl apply -f apps/grc/audit.yaml
kubectl apply -f apps/grc/sanction.yaml
```

Apply the GRC HTTPRoute:

```bash
kubectl apply -f apps/grc/02-fraud-httproute.yaml
```

Verify:

```bash
kubectl get gateway -n grc-kic
kubectl get httproute -n grc-team
kubectl get pods,svc -n grc-team
```

################################################################################
# 10. Enable Istio mTLS
################################################################################

Rollout is two phases: PERMISSIVE first so you can confirm sidecars are running,
then STRICT to enforce encryption on every in-cluster hop.

## Phase 1 – PERMISSIVE mode + DestinationRules

Apply mesh-wide PERMISSIVE mode. This allows both plaintext and mTLS while you
confirm every workload has a sidecar:

```bash
kubectl apply -f istio/00-mtls-permissive.yaml
```

Apply the DestinationRules. These tell each caller's Envoy sidecar to originate
Istio mTLS for every downstream host — covering all three hops:
Global Kong → domain KIC → first service → service chain.

```bash
kubectl apply -f istio/05-destinationrules-istio-mutual.yaml
```

## Verify sidecar injection

Check that every pod in the mesh namespaces has an `istio-proxy` container:

```bash
kubectl get pods -n global-kic -o jsonpath='{range .items[*]}{.metadata.name}{"  "}{.spec.containers[*].name}{"\n"}{end}'
kubectl get pods -n retail-banking-kic -o jsonpath='{range .items[*]}{.metadata.name}{"  "}{.spec.containers[*].name}{"\n"}{end}'
kubectl get pods -n retail-banking-team -o jsonpath='{range .items[*]}{.metadata.name}{"  "}{.spec.containers[*].name}{"\n"}{end}'
kubectl get pods -n payments-kic -o jsonpath='{range .items[*]}{.metadata.name}{"  "}{.spec.containers[*].name}{"\n"}{end}'
kubectl get pods -n payments-team -o jsonpath='{range .items[*]}{.metadata.name}{"  "}{.spec.containers[*].name}{"\n"}{end}'
kubectl get pods -n grc-kic -o jsonpath='{range .items[*]}{.metadata.name}{"  "}{.spec.containers[*].name}{"\n"}{end}'
kubectl get pods -n grc-team -o jsonpath='{range .items[*]}{.metadata.name}{"  "}{.spec.containers[*].name}{"\n"}{end}'
```

Each pod must list its application container **and** `istio-proxy`. If any pod
is missing the sidecar (deployed before the namespace was labeled), restart it:

```bash
kubectl rollout restart deployment -n global-kic
kubectl rollout restart deployment -n retail-banking-kic
kubectl rollout restart deployment -n retail-banking-team
kubectl rollout restart deployment -n payments-kic
kubectl rollout restart deployment -n payments-team
kubectl rollout restart deployment -n grc-kic
kubectl rollout restart deployment -n grc-team
```

Confirm traffic still works in PERMISSIVE mode before proceeding:

```bash
GLOBAL_LB=$(kubectl get svc -n global-kic global-kic-gateway-proxy \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

curl -H "Host: mybank.mini-apps.click" "http://${GLOBAL_LB}/retail-banking"
curl -H "Host: mybank.mini-apps.click" "http://${GLOBAL_LB}/payments"
curl -H "Host: mybank.mini-apps.click" "http://${GLOBAL_LB}/grc"
```

## Phase 2 – STRICT mode

Once all pods show an `istio-proxy` sidecar and the routes work, enforce STRICT
mTLS for all internal namespaces. This blocks any plaintext connection to the
domain KIC and app pods:

```bash
kubectl apply -f istio/10-mtls-strict-internal.yaml
```

`global-kic` is intentionally left at mesh-wide PERMISSIVE so public HTTPS
clients can reach the edge gateway. All traffic *leaving* `global-kic` is still
mTLS via the DestinationRules.

Validate again after switching to STRICT:

```bash
curl -H "Host: mybank.mini-apps.click" "http://${GLOBAL_LB}/retail-banking"
curl -H "Host: mybank.mini-apps.click" "http://${GLOBAL_LB}/payments"
curl -H "Host: mybank.mini-apps.click" "http://${GLOBAL_LB}/grc"
```

Expected result:
- Public client → Global Kong: normal HTTP/HTTPS edge traffic.
- Global Kong → domain KIC proxy: Istio mTLS (DestinationRule ISTIO_MUTUAL).
- Domain KIC → backend services: Istio mTLS.
- Service-to-service inside each domain: Istio mTLS.
- Plaintext direct calls to STRICT internal workloads: blocked (connection reset).

## Roll back STRICT mode

If STRICT mode exposes a workload without a sidecar, return to PERMISSIVE:

```bash
kubectl delete -f istio/10-mtls-strict-internal.yaml --ignore-not-found
kubectl apply -f istio/00-mtls-permissive.yaml
kubectl apply -f istio/05-destinationrules-istio-mutual.yaml
```

Fix sidecar injection for the affected pod, then retry STRICT mode.

################################################################################
# 11. Configure DNS
################################################################################

Find the external address of the global Kong Gateway proxy service:

```bash
kubectl get svc -n global-kic
```

Look for the global Kong proxy service, usually named:

```text
global-kic-gateway-proxy
```

Copy the `EXTERNAL-IP` value. On AWS, this is normally an ELB DNS name similar to:

```text
xxxxxxxx.ap-southeast-1.elb.amazonaws.com
```

Create or update this DNS record:

```text
mybank.mini-apps.click -> global Kong Gateway load balancer
```

In Route 53, create the CNAME record with these values:

```text
Record name: mybank
Record type: CNAME
Value: <global-kic-gateway-proxy EXTERNAL-IP / ELB DNS name>
TTL: 300
Routing policy: Simple routing
Alias: Off
```

Example:

```text
Record name: mybank
Record type: CNAME
Value: abc123.ap-southeast-1.elb.amazonaws.com
TTL: 300
Routing policy: Simple routing
Alias: Off
```

Do not include `http://` or `https://` in the CNAME value.

Verify DNS:

```bash
nslookup mybank.mini-apps.click
```

If you also want to test downstream gateways directly, create DNS records for:

```text
retail-banking.mini-apps.click -> retail-banking Kong Gateway load balancer
payments.mini-apps.click       -> payments Kong Gateway load balancer
grc.mini-apps.click            -> grc Kong Gateway load balancer
```

################################################################################
# 12. Test the global gateway
################################################################################

Test Retail Banking:

```bash
curl -i http://mybank.mini-apps.click/retail-banking
```

Test Payments:

```bash
curl -i http://mybank.mini-apps.click/payments
```

Test GRC:

```bash
curl -i http://mybank.mini-apps.click/grc
```

Expected traffic path:

```text
Client
  -> mybank.mini-apps.click/<domain-path>
  -> global Kong Gateway
  -> ExternalName service
  -> downstream Kong Gateway proxy service
  -> downstream HTTPRoute
  -> application service
```

################################################################################
# 13. Useful troubleshooting commands
################################################################################

Check all gateways:

```bash
kubectl get gateway -A
```

Check all routes:

```bash
kubectl get httproute -A
```

Describe the global route:

```bash
kubectl describe httproute global-httproute -n global-api-gateway-ns
```

Check the `ExternalName` services:

```bash
kubectl get svc -n global-api-gateway-ns
kubectl describe svc payments-kic-gateway-proxy -n global-api-gateway-ns
```

Check application pods:

```bash
kubectl get pods -n retail-banking-team
kubectl get pods -n payments-team
kubectl get pods -n grc-team
```

Check application logs:

```bash
kubectl logs -n retail-banking-team deploy/customer-profile-svc
kubectl logs -n payments-team deploy/transfer-svc
kubectl logs -n grc-team deploy/fraud-svc
```

Check Istio mTLS policies:

```bash
kubectl get peerauthentication -A
kubectl describe peerauthentication default -n retail-banking-team
kubectl describe peerauthentication default -n payments-team
kubectl describe peerauthentication default -n grc-team
```

Check sidecars:

```bash
kubectl get pods -n global-kic -o jsonpath='{range .items[*]}{.metadata.name}{"  "}{.spec.containers[*].name}{"\n"}{end}'
kubectl get pods -n retail-banking-kic -o jsonpath='{range .items[*]}{.metadata.name}{"  "}{.spec.containers[*].name}{"\n"}{end}'
kubectl get pods -n payments-kic -o jsonpath='{range .items[*]}{.metadata.name}{"  "}{.spec.containers[*].name}{"\n"}{end}'
kubectl get pods -n grc-kic -o jsonpath='{range .items[*]}{.metadata.name}{"  "}{.spec.containers[*].name}{"\n"}{end}'
```

################################################################################
# 14. Optional HTTPS setup
################################################################################

The `for_https` directory contains Terraform files for Let's Encrypt certificates and HTTPS listeners.

Prepare the Terraform variables:

```bash
cd for_https
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set your ACME email address.

Run Terraform:

```bash
terraform init
terraform plan
terraform apply
```

Verify TLS secrets:

```bash
kubectl get secret -n global-kic
kubectl get secret -n retail-banking-kic
kubectl get secret -n payments-kic
kubectl get secret -n grc-kic
```

Test HTTPS:

```bash
curl -i https://mybank.mini-apps.click/retail-banking
curl -i https://mybank.mini-apps.click/payments
curl -i https://mybank.mini-apps.click/grc
```

################################################################################
# 15. Cleanup
################################################################################

Delete Istio mTLS policies:

```bash
kubectl delete -f istio/10-mtls-strict-internal.yaml --ignore-not-found
kubectl delete -f istio/05-destinationrules-istio-mutual.yaml --ignore-not-found
kubectl delete -f istio/00-mtls-permissive.yaml --ignore-not-found
```

Delete GRC resources:

```bash
kubectl delete -f apps/grc/02-fraud-httproute.yaml
kubectl delete -f apps/grc/sanction.yaml
kubectl delete -f apps/grc/audit.yaml
kubectl delete -f apps/grc/fraud.yaml
kubectl delete -f apps/grc/01-grc-kong-api-gateway.yaml
kubectl delete -f apps/grc/00-grc-gatewayclass.yaml
kubectl delete -f apps/grc/grc-ns.yaml
```

Delete Payments resources:

```bash
kubectl delete -f apps/payments/02-transfer-httproute.yaml
kubectl delete -f apps/payments/fx-svc.yaml
kubectl delete -f apps/payments/payment-gateway.yaml
kubectl delete -f apps/payments/transfer-svc.yaml
kubectl delete -f apps/payments/01-payments-kong-api-gateway.yaml
kubectl delete -f apps/payments/00-payments-gatewayclass.yaml
kubectl delete -f apps/payments/payments-ns.yaml
```

Delete Retail Banking resources:

```bash
kubectl delete -f apps/retail-banking/02-customer-profile-httproute.yaml
kubectl delete -f apps/retail-banking/statement-service.yaml
kubectl delete -f apps/retail-banking/account-service.yaml
kubectl delete -f apps/retail-banking/customer-profile-service.yaml
kubectl delete -f apps/retail-banking/01-retail-banking-kong-api-gateway.yaml
kubectl delete -f apps/retail-banking/00-retail-banking-gatewayclass.yaml
```

Delete global resources:

```bash
kubectl delete -f 2-global-httproute.yaml
kubectl delete -f 3-downstream-proxy-services.yaml
kubectl delete -f 1-kong-api-gateway-global.yaml
kubectl delete -f 0-gatewayclass-global.yaml
```

Uninstall Kong controller instances:

```bash
helm uninstall global-kic -n global-kic
helm uninstall retail-banking-kic -n retail-banking-kic
helm uninstall payments-kic -n payments-kic
helm uninstall grc-kic -n grc-kic
```

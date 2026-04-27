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
# 4. Install Kong Ingress Controller instances
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

The downstream proxy services shown here are the real services targeted by the `ExternalName` services in `2-downstream-proxy-services.yaml`.

################################################################################
# 5. Deploy the global gateway layer
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
kubectl apply -f 2-downstream-proxy-services.yaml
```

Apply the global HTTPRoute:

```bash
kubectl apply -f 3-global-httproute.yaml
```

Verify:

```bash
kubectl get gatewayclass
kubectl get gateway -n global-kic
kubectl get httproute -n global-api-gateway-ns
kubectl get svc -n global-api-gateway-ns
```

################################################################################
# 6. Deploy Retail Banking
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
# 7. Deploy Payments
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
# 8. Deploy GRC
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
# 9. Configure DNS
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
# 10. Test the global gateway
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
# 11. Useful troubleshooting commands
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

################################################################################
# 12. Optional HTTPS setup
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
# 13. Cleanup
################################################################################

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
kubectl delete -f 3-global-httproute.yaml
kubectl delete -f 2-downstream-proxy-services.yaml
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

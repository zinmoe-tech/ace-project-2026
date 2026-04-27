# Kong Distributed Gateway on EKS - setup commands
#
# This file is a command runbook. Run the commands manually, step by step.
# Values used by this project:
# - AWS profile: demo-microservices
# - AWS region: ap-southeast-1
# - EKS cluster: demo-eks-cluster
# - DNS zone: mini-apps.click

################################################################################
# 1. Create or connect to the EKS cluster
################################################################################

eksctl create cluster \
  --name demo-eks-cluster \
  --region ap-southeast-1 \
  --version 1.34 \
  --instance-types t3.medium \
  --nodes-min 3 \
  --profile aws-profile

aws eks update-kubeconfig \
  --name demo-eks-cluster \
  --region ap-southeast-1 \
  --profile aws-profile

kubectl get nodes
kubectl get ns

eksctl get cluster \
  --region ap-southeast-1 \
  --profile aws-profile

################################################################################
# 2. Install Gateway API CRDs
################################################################################

kubectl apply --server-side \
  -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.1/standard-install.yaml

kubectl api-resources --api-group=gateway.networking.k8s.io

################################################################################
# 3. Install Kong Ingress Controller for each domain
################################################################################

helm repo add kong https://charts.konghq.com
helm repo update

helm install retail-banking-kic kong/ingress \
  --namespace retail-banking-kic \
  --create-namespace \
  --set controller.ingressController.env.gateway_api_controller_name=konghq.com/retail-banking-kong-gateway-controller

helm install payments-kic kong/ingress \
  --namespace payments-kic \
  --create-namespace \
  --set controller.ingressController.env.gateway_api_controller_name=konghq.com/payments-kong-gateway-controller

helm install grc-kic kong/ingress \
  --namespace grc-kic \
  --create-namespace \
  --set controller.ingressController.env.gateway_api_controller_name=konghq.com/grc-kong-gateway-controller

kubectl get pods -A | grep kic
kubectl get svc -A | grep gateway-proxy

################################################################################
# 4. Apply domain Gateway API resources and workloads
################################################################################

kubectl apply -f apps/retail-banking/retail-banking-gatewayclass.yaml
kubectl apply -f apps/retail-banking/retail-banking-kong-api-gateway.yaml
kubectl apply -f apps/retail-banking/customer-profile-service.yaml
kubectl apply -f apps/retail-banking/account-service.yaml
kubectl apply -f apps/retail-banking/statement-service.yaml
kubectl apply -f apps/retail-banking/customer-profile-httproute.yaml

kubectl apply -f apps/payments/payments-gatewayclass.yaml
kubectl apply -f apps/payments/payments-kong-api-gateway.yaml
kubectl apply -f apps/payments/payments-ns.yaml
kubectl apply -f apps/payments/transfer-svc.yaml
kubectl apply -f apps/payments/payment-gateway.yaml
kubectl apply -f apps/payments/fx-svc.yaml
kubectl apply -f apps/payments/transfer-httproute.yaml

kubectl apply -f apps/grc/grc-gatewayclass.yaml
kubectl apply -f apps/grc/grc-kong-api-gateway.yaml
kubectl apply -f apps/grc/grc-ns.yaml
kubectl apply -f apps/grc/fraud.yaml
kubectl apply -f apps/grc/audit.yaml
kubectl apply -f apps/grc/sanction.yaml
kubectl apply -f apps/grc/fraud-httproute.yaml

kubectl get gateway -A
kubectl get httproute -A
kubectl get pods,svc -n retail-banking
kubectl get pods,svc -n payments
kubectl get pods,svc -n grc

################################################################################
# 5. Optional: apply the global Gateway API layer
################################################################################

kubectl apply -f kong/0-gatewayclass-global.yaml
kubectl apply -f kong/1-kong-api-gateway-global.yaml
kubectl apply -f kong/2-referencegrants.yaml
kubectl apply -f kong/3-global-httproute.yaml

kubectl get gateway -A
kubectl get httproute -A
kubectl get referencegrant -A

################################################################################
# 6. Configure Route 53
################################################################################
#
# Create A alias records in the public hosted zone mini-apps.click:
#
# retail-banking.mini-apps.click -> retail-banking-kic-gateway-proxy ELB
# payments.mini-apps.click       -> payments-kic-gateway-proxy ELB
# grc.mini-apps.click            -> grc-kic-gateway-proxy ELB
#
# Get the ELB hostnames:

kubectl get svc -A | grep gateway-proxy

################################################################################
# 7. Test HTTP
################################################################################

curl -i http://retail-banking.mini-apps.click/
curl -i http://payments.mini-apps.click/
curl -i http://grc.mini-apps.click/

# If DNS has not propagated locally, test with an ELB and Host header:
#
# curl -i -H "Host: retail-banking.mini-apps.click" http://<retail-banking-elb>/
# curl -i -H "Host: payments.mini-apps.click" http://<payments-elb>/
# curl -i -H "Host: grc.mini-apps.click" http://<grc-elb>/

################################################################################
# 8. Optional: enable HTTPS
################################################################################

cd for_https
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars and set acme_email.

terraform init
terraform plan
terraform apply

curl -i https://retail-banking.mini-apps.click/
curl -i https://payments.mini-apps.click/
curl -i https://grc.mini-apps.click/

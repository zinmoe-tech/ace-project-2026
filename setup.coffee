1-#spin up eks cluster
eksctl create cluster --name demo-eks-cluster --region ap-southeast-1 --version 1.34 --instance-types t3.medium --nodes-min 3 --profile demo-microservices

2-#Update kubeconfig
aws eks update-kubeconfig \
  --name demo-eks-cluster \
  --region ap-southeast-1 \
  --profile demo-microservices

3-#Check eks cluster status
kubectl get nodes
kubectl get ns

eksctl get cluster \
  --region ap-southeast-1 \
  --profile demo-microservices

4-# Install Kong Ingress Controller for each application with unique gateway API controller names
helm install retail-banking-kic kong/ingress \
  --namespace retail-banking-kic --create-namespace \
  --set controller.ingressController.env.gateway_api_controller_name=konghq.com/retail-banking-kong-gateway-controller

helm install payments-kic kong/ingress \
  --namespace payments-kic --create-namespace \
  --set controller.ingressController.env.gateway_api_controller_name=konghq.com/payments-kong-gateway-controller

helm install grc-kic kong/ingress \
  --namespace grc-kic --create-namespace \
  --set controller.ingressController.env.gateway_api_controller_name=konghq.com/grc-kong-gateway-controller

5-# Install Gateway API CRDs
kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.1/standard-install.yaml

# External users
Internet -> Global API Gateway

# Internal/VPC users
VPC -> Domain-specific internal LoadBalancer -> retail/payments gateway

## For retail-banking
kubectl delete svc retail-banking-kic-gateway-proxy -n retail-banking-kic

helm upgrade retail-banking-kic kong/ingress \
  --namespace retail-banking-kic \
  --reuse-values \
  --set gateway.proxy.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-scheme"=internal \
  --set gateway.proxy.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-internal"="true"

## For payments
kubectl delete svc payments-kic-gateway-proxy -n payments-kic

helm upgrade payments-kic kong/ingress \
  --namespace payments-kic \
  --reuse-values \
  --set gateway.proxy.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-scheme"=internal \
  --set gateway.proxy.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-internal"="true"

## For grc
kubectl annotate svc grc-kic-gateway-proxy \
  -n grc-kic \
  service.beta.kubernetes.io/aws-load-balancer-scheme=internal \
  --overwrite

kubectl get svc -A | grep gateway-proxy

External users:
https://finance.ky-cloud.click/retail-banking
https://finance.ky-cloud.click/payments
https://finance.ky-cloud.click/grc

Internal users:
http://retail-banking.internal.ky-cloud.click
http://payments.internal.ky-cloud.click
http://grc.internal.ky-cloud.click

kubectl run test-curl -n retail-banking-ns --rm -it \
  --image=curlimages/curl -- sh
curl -H "Host: retail-banking.ky-cloud.click" \
http://internal-a6a64de819b8a4e0db92ad35a6f8627c-883339418.ap-southeast-1.elb.amazonaws.com

kubectl run test-curl -n payments-ns --rm -it \
  --image=curlimages/curl -- sh
curl -H "Host: payments.ky-cloud.click" http://internal-a539c4bb5e6284c929d031b15b6e768f-1807593033.ap-southeast-1.elb.amazonaws.com

curl -H "Host: grc.ky-cloud.click" http://a5a1e803baf354197b31c90925fa490d-131287375.ap-southeast-1.elb.amazonaws.com
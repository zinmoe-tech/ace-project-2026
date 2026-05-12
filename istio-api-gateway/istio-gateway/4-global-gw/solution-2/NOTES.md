# Install global Kong Ingress Controller

helm install global-kic kong/ingress \
  --namespace global-kic --create-namespace \
  --set controller.ingressController.env.gateway_api_controller_name=konghq.com/global-kong-gateway-controller

k apply -f 0-gatewayclass-global.yaml
k apply -f 1-kong-api-gateway-global.yaml
k apply -f 2-downstream-proxy-services.yaml
k apply -f 3-global-httproute.yaml

curl -H "Host: finance.ky-cloud.click" http://172.18.255.193/retail-banking
curl -H "Host: finance.ky-cloud.click" http://172.18.255.193/payments

curl -H "Host: finance.ky-cloud.click" http://ab23cc51571f145edaa837fe4621389c-80265999.ap-southeast-1.elb.amazonaws.com/retail-banking

# Test (should work)
curl http://finance.ky-cloud.click/retail-banking
curl http://finance.ky-cloud.click/payments
curl http://finance.ky-cloud.click/grc

# Test (should still work)
curl http://retail-banking.ky-cloud.click
curl http://payments.ky-cloud.click
curl http://grc.ky-cloud.click
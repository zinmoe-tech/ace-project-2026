# request certificate in aws certificate manager

# edit service
kubectl edit svc global-kic-gateway-proxy -n global-kic

metadata:
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-ssl-cert: <ACM_CERT_ARN>
    service.beta.kubernetes.io/aws-load-balancer-ssl-ports: "443"

# check port
ports:
  - name: kong-proxy
    port: 80
    protocol: TCP
    targetPort: 8000
  - name: kong-proxy-tls
    port: 443
    protocol: TCP
    targetPort: 8000

# access with https
curl -v https://finance.ky-cloud.click/retail-banking
curl -v https://finance.ky-cloud.click/payments
curl -v https://finance.ky-cloud.click/grc
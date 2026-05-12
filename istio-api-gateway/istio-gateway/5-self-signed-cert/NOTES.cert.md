helm install cert-manager oci://quay.io/jetstack/charts/cert-manager \
  --version v1.20.2 \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true

# create certificate
kubectl apply -f 1-cluster-issue.yaml
kubectl apply -f 2-retail-banking-cert.yaml
kubectl apply -f 3-payments-cert.yaml

# verify certificate
kubectl get certificate -A
kubectl describe certificate retail-banking-cert -n retail-banking-kic
kubectl describe certificate payments-cert -n payments-kic
kubectl get secret -n retail-banking-kic retail-banking-tls
kubectl get secret -n payments-kic payments-tls

# Update each Gateway to add an HTTPS listener
kubectl apply -f 4-kong-api-gateway-retail-banking.yaml
kubectl apply -f 5-kong-api-gateway-payments.yaml

# Bind your HTTPRoutes to the HTTPS listener
kubectl apply -f 2-customer-profile-httproute.yaml
kubectl apply -f 2-transfer-httproute.yaml

# curl test
curl -vk --resolve retail-banking.ky-cloud.click:443:a00159761a9d9497eb9dba73c05f1494-1493062102.ap-southeast-1.elb.amazonaws.com \
https://retail-banking.ky-cloud.click/

curl -vk \
--connect-to retail-banking.ky-cloud.click:443:a00159761a9d9497eb9dba73c05f1494-1493062102.ap-southeast-1.elb.amazonaws.com:443 \
https://retail-banking.ky-cloud.click/

curl -vk --resolve payments.ky-cloud.click:443:172.18.255.191 \
  https://payments.ky-cloud.click/

curl -vk \
-H "Host: retail-banking.ky-cloud.click" \
https://a00159761a9d9497eb9dba73c05f1494-1493062102.ap-southeast-1.elb.amazonaws.com

# with secure
kubectl get secret retail-banking-tls -n retail-banking-kic \
  -o jsonpath='{.data.tls\.crt}' | base64 -d > retail-banking.crt

kubectl get secret payments-tls -n payments-kic \
  -o jsonpath='{.data.tls\.crt}' | base64 -d > payments.crt

curl -v --cacert retail-banking.crt \
  --resolve retail-banking.ky-cloud.click:443:172.18.255.190 \
  https://retail-banking.ky-cloud.click/

curl -v --cacert payments.crt \
  --resolve payments.ky-cloud.click:443:172.18.255.191 \
  https://payments.ky-cloud.click/

curl -v --cacert retail-banking.crt \
  https://a00159761a9d9497eb9dba73c05f1494-1493062102.ap-southeast-1.elb.amazonaws.com
istioctl install --set profile=demo -y
kubectl label namespace retail-banking-ns istio-injection=enabled
kubectl rollout restart deployment -n retail-banking-ns

seenvoy -t http://localhost:9901

echo '' | base64 -d | openssl x509 -text -noout

while true; do curl -H "Host: retail-banking.ky-cloud.click" http://172.18.255.190; sleep 0.3; done

export ISTIO_VERSION=1.29.2
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${ISTIO_VERSION} sh -


hey -n 100 -c 10 -host "retail-banking.ky-cloud.click" http://172.18.255.190/

https://github.com/sailinnthu/hellocloud-native-box-sai/tree/main/istio-cop/1-start-istio
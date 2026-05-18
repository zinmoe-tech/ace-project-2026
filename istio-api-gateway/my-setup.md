Date : 09May2026

1 - set up kind-cluster

2 - Install istio
istioctl install --set profile=default \
  --set components.egressGateways[0].name=istio-egressgateway \
  --set components.egressGateways[0].enabled=true \
  -y

3 - Forward port of Istio Ingress Gateway pod
kubectl port-forward deployment/istio-ingressgateway -n istio-system 15000:15000

4 - Access the below address on your browser
localhost:15000 >> config_dump
localhost:15000 >> listeners
[localhost:15000 >> stats](http://localhost:15000/stats/prometheus?usedonly) (It will show you used only matrix)

5 - Search total service with "observability_name"
Key : We call cluster for service in Istio System.

6 - How to check by using istioctl proxy-config command with order
istioctl proxy-config --help
1st check point >>> listeners
2nd check point >>> route
3rd check point >>> clusters
4th check point >>> endpoints
5th check point >>> secret

Available Commands:
  all            Retrieves all configuration for the Envoy in the specified pod
  bootstrap      Retrieves bootstrap configuration for the Envoy in the specified pod
  cluster        Retrieves cluster configuration for the Envoy in the specified pod
  ecds           Retrieves typed extension configuration for the Envoy in the specified pod
  endpoint       Retrieves endpoint configuration for the Envoy in the specified pod
  listener       Retrieves listener configuration for the Envoy in the specified pod
  log            Retrieves logging levels of the Envoy in the specified pod
  rootca-compare Compare ROOTCA values for the two given pods
  route          Retrieves route configuration for the Envoy in the specified pod
  secret         Retrieves secret configuration for the Envoy in the specified pod

7 - How to see data from seenvoy
kubectl port-forward deployment/istio-ingressgateway -n istio-system 9901:15000

seenvoy -t http://localhost:9901

curl -H "Host: retail-banking.ky-cloud.click" http://172.18.255.180

###Istio add on installation for observility
1. check version
$istioctl version
<or>
$istioctl proxy-status

2. export ISTIO_VERSION=1.24.0

3. curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${ISTIO_VERSION} sh -

4. kubectl apply -f /home/zinmoe/Desktop/ace-project-2026/ace-project-2026/istio-api-gateway/istio-1.24.0/samples/addons

while true; do curl -H "Host: retail-banking.ky-cloud.click" http://172.18.255.180; sleep 0.5; done


# prometheus 9090
kubectl port-forward -n istio-system svc/prometheus --address 0.0.0.0 9090:9090

# grafana 3000
kubectl port-forward -n istio-system svc/grafana --address 0.0.0.0 3000:3000

hey -n 1000 -c 100 -host "retail-banking.ky-cloud.click" http://172.18.255.180/

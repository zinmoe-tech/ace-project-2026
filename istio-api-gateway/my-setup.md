Date : 09May2026

1 - set up kind-cluster

2 - Install istio
istioctl install --set profile=default \
  --set components.egressGateways[0].name=istio-egressgateway \
  --set components.egressGateways[0].enabled=true \
  -y

3 - Forward port of Istio Ingress Gateway pod
kubectl port-forward pod/istio-ingressgateway-85c8f4b645-9gns4 -n istio-system 15000:15000

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
kubectl port-forward pod/istio-ingressgateway-85c8f4b645-9gns4 -n istio-system 9901:15000

seenvoy -t http://localhost:9901

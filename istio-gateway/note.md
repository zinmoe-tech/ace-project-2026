kubectl delete deployment -n retail-banking-team retail-banking-istio-ingressgateway --ignore-not-found
kubectl delete deployment -n payments-team payments-istio-ingressgateway --ignore-not-found
kubectl delete deployment -n grc-team grc-istio-ingressgateway --ignore-not-found

istioctl install -f istio-gateway/minimal-profile.yaml -y

-----------------------------------------------------------

Access to docker control plane
$ docker exec -it 134-control-plane /bin/sh

Under /etc/kubernetes/pki
$ cd /etc/kubernetes/pki

What are sa.key and sa.pub?

------------------------------------------------------------
Check control plane ip address

$ kubectl get pods -n kube-system -o wide
NAME                                        READY   STATUS    RESTARTS        AGE     IP           NODE                NOMINATED NODE   READINESS GATES
coredns-66bc5c9577-6xpvf                    1/1     Running   1 (5h25m ago)   24h     10.252.0.4   134-control-plane   <none>           <none>
coredns-66bc5c9577-d4zvg                    1/1     Running   1 (5h25m ago)   24h     10.252.0.2   134-control-plane   <none>           <none>
etcd-134-control-plane                      1/1     Running   0               5h25m   172.19.0.3   134-control-plane   <none>           <none>
kindnet-g4ntn                               1/1     Running   1 (5h25m ago)   24h     172.19.0.3   134-control-plane   <none>           <none>
kindnet-prgs7                               1/1     Running   1 (5h25m ago)   24h     172.19.0.5   134-worker3         <none>           <none>
kindnet-r9lgs                               1/1     Running   1 (5h25m ago)   24h     172.19.0.4   134-worker2         <none>           <none>
kindnet-x9wt6                               1/1     Running   1 (5h25m ago)   24h     172.19.0.2   134-worker          <none>           <none>
kube-apiserver-134-control-plane            1/1     Running   0               5h25m   172.19.0.3   134-control-plane   <none>           <none>
kube-controller-manager-134-control-plane   1/1     Running   1 (5h25m ago)   24h     172.19.0.3   134-control-plane   <none>           <none>
kube-proxy-5hdq4                            1/1     Running   1 (5h25m ago)   24h     172.19.0.3   134-control-plane   <none>           <none>
kube-proxy-p4vw2                            1/1     Running   1 (5h25m ago)   24h     172.19.0.5   134-worker3         <none>           <none>
kube-proxy-sbtt4                            1/1     Running   1 (5h25m ago)   24h     172.19.0.4   134-worker2         <none>           <none>
kube-proxy-vsstp                            1/1     Running   1 (5h25m ago)   24h     172.19.0.2   134-worker          <none>           <none>
kube-scheduler-134-control-plane            1/1     Running   1 (5h25m ago)   24h     172.19.0.3   134-control-plane   <none>           <none>


$ kubectl get ep 
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME         ENDPOINTS         AGE
kubernetes   172.19.0.3:6443   24h


-------------------------------------------------------------------------------------
Attemp to access kube api server

$ curl -k https://172.19.0.3:6443 ### -k help to skip certificate
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {},
  "status": "Failure",
  "message": "forbidden: User \"system:anonymous\" cannot get path \"/\"",
  "reason": "Forbidden",
  "details": {},
  "code": 403

$ curl -k https://172.19.0.3:6443/version

{
  "major": "1",
  "minor": "34",
  "emulationMajor": "1",
  "emulationMinor": "34",
  "minCompatibilityMajor": "1",
  "minCompatibilityMinor": "33",
  "gitVersion": "v1.34.0",
  "gitCommit": "f28b4c9efbca5c5c0af716d9f2d5702667ee8a45",
  "gitTreeState": "clean",
  "buildDate": "2025-08-27T10:09:04Z",
  "goVersion": "go1.24.6",
  "compiler": "gc",
  "platform": "linux/amd64"
}

-----------------------------------------------------------------------

Validation endpoint 

$ kubectl get --raw /.well-known/openid-configuration | jq
{
  "issuer": "https://kubernetes.default.svc.cluster.local",
  "jwks_uri": "https://172.19.0.3:6443/openid/v1/jwks",
  "response_types_supported": [
    "id_token"
  ],
  "subject_types_supported": [
    "public"
  ],
  "id_token_signing_alg_values_supported": [
    "RS256"
  ]
}

Validation Endpoint is jwks_uri

$ kubectl get --raw /openid/v1/jwks | jq
{
  "keys": [
    {
      "use": "sig",
      "kty": "RSA",
      "kid": "8jrSHooTPnankd1vqkSFnaU639zJouFQJBuTMCrQTrE",
      "alg": "RS256",
      "n": "yrWt05Gz7-jSaxMnDEP6eNwXeyVEyb4l5KPyQBIu5PrEnCNPWzcdHwXuQUa7cmvSLZ6q4GYwJLCimRDvVNpylcTTpuQytJ9SwLRKVwFLd08R7PcSQ5rCHzafWvUdCkFIRXca2GFU7epRJYkB8CqMx_QSA0-r26N84GSbFmChUJ8mK4sfvpjmw7I7khmvUlwUHm6YZJ10NjM29EwWGUhNJdUzUFg3NCZIAM9OaLpB1B8Nq0_5BVGaqgXwNVH8GrpqKFXahNnAm9HEA6Zv-b7Q2KcsnYTYoL4UtJxrDdauWm9OP7QBn-bzfVNCi_ZlJrJCJTx4Mc_4XYbH3M6qxrP-bQ",
      "e": "AQAB"
    }
  ]
}

We can't call it because of vaid certificate to access

curl -k https://172.19.0.3:6443/openid/v1/jwks
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {},
  "status": "Failure",
  "message": "forbidden: User \"system:anonymous\" cannot get path \"/openid/v1/jwks\"",
  "reason": "Forbidden",
  "details": {},
  "code": 403
}
-----------------------------------------------------------------

Let access it by adding certificate or token

How do we get ca cert?

In kubernetes api server,

cat ca.crt

Check service account first:
Use a ServiceAccount token.
Create one token:

kubectl create token default(sa name) -n default
$ kubectl create token default -n default

export TOKEN=$(kubectl create token default -n default)

TOKEN=$(kubectl create token default -n default)

curl --cacert ./ca.crt \
  -H "Authorization: Bearer $TOKEN" \
  https://172.19.0.3:6443/openid/v1/jwks | jq


              ┌─────────────────────────────────────────────────┐
              │  BROWSER                                        │
              │  finance.hellocloud.io/retail-banking/accounts  │
              └───────────────────────┬─────────────────────────┘
                                      │  /etc/hosts → 172.19.255.201
                                      ▼
╔══ namespace: global-kic ════════════════════════════════════════════╗
║                                                                     ║
║   Service: global-kic-gateway-proxy   ·   LB 172.19.255.201:80      ║
║                          │                                          ║
║                          ▼                                          ║
║   Kong proxy POD   ◀╌╌╌╌╌  Gateway: global-kong-globalgateway       ║
║                          │            (listener :80)                ║
╚══════════════════════════╪═══════════════════════════════════════════╝
                           │  GET /retail-banking/accounts
                           ▼
╔══ namespace: global-api-gateway-ns ═════════════════════════════════╗
║                                                                     ║
║   HTTPRoute: global-httproute                                       ║
║     • match       PathPrefix /retail-banking/accounts               ║
║     • URLRewrite  ──▶ /accounts                                     ║
║                          │                                          ║
╚══════════════════════════╪═══════════════════════════════════════════╝
       ReferenceGrant       │  GET /accounts   (path now rewritten)
  allow-global-httproute ╌╌╌┤
   (authorizes cross-ns)    ▼
╔══ namespace: retail-banking-team ═══════════════════════════════════╗
║                                                                     ║
║   Service: retail-banking-istio-ingressgateway  ·  port 80 ▶ 8080   ║
║                          │                                          ║
║                          ▼                                          ║
║   Istio ingress gateway POD  (Envoy)                                ║
║     listener :8080  +  route /accounts                              ║
║          ▲                                                          ║
║          ╎◀╌╌ Gateway: retail-banking-gateway         ──▶ LDS        ║
║          ╎◀╌╌ VirtualService: retail-banking-routes   ──▶ RDS        ║
║                          │  GET /accounts · Host: finance… · mTLS    ║
║                          ▼                                           ║
║   Service: account-svc   ·   port 8082 ▶ targetPort 9092            ║
║                          │                                           ║
║                          ▼                                           ║
║   account-svc POD   [ app :9092  +  istio-proxy sidecar ]           ║
║                          │  app upstream call                       ║
║                          ▼                                           ║
║   statement-svc   :8083                                             ║
╚═════════════════════════════════════════════════════════════════════╝

   CONTROL PLANE
   istiod (istio-system) watches Gateway + VirtualService, compiles them
   into Envoy listener (LDS) + route (RDS), and pushes to the ingress
   gateway POD over xDS :15012.

   ──▶  request traffic (data plane)
   ╌╌▶  configuration / authorization (control plane)

    echo "172.18.255.190  finance.hellocloud.io" | sudo tee -a /etc/hosts

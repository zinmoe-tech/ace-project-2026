Step 1 — Create the kind cluster
bash# Make sure you're inside the repo root
cd k8s-idp

# Create the cluster
kind create cluster --config kind-config.yaml
Wait ~1 minute. Then check nodes:
bashkubectl get nodes
You'll see this — NotReady is expected because there's no CNI yet:
NAME                        STATUS     ROLES           AGE
idp-cluster-control-plane   NotReady   control-plane   30s
idp-cluster-worker          NotReady   <none>          28s
idp-cluster-worker2         NotReady   <none>          28s
idp-cluster-worker3         NotReady   <none>          28s
Tell me when you see this output and we move to Step 2.

Step 2 — Install the Cilium CLI
This is a standalone tool on your laptop — separate from the cluster:
bash# macOS
brew install cilium-cli

# Verify
cilium version --client
Expected output:
cilium-cli: v0.16.10

Step 3 — Add the Cilium Helm repo
bash# Add Cilium's official Helm repo
helm repo add cilium https://helm.cilium.io/

# Fetch latest chart index
helm repo update

# Confirm it's there
helm search repo cilium/cilium
Expected output:

NAME            CHART VERSION   APP VERSION
cilium/cilium   1.15.5          1.15.5

Step 4 — Pre-load the Cilium image into kind nodes
Kind nodes are Docker containers. Without this step, each node would pull the Cilium image from the internet at startup — slow and fragile. Pre-loading puts the image directly inside the kind nodes:

# Pull image to your local Docker first
docker pull quay.io/cilium/cilium:v1.15.5

# Push it into all kind cluster nodes
kind load docker-image quay.io/cilium/cilium:v1.15.5 \
  --name idp-cluster

Expected output:
Image: "quay.io/cilium/cilium:v1.15.5" with ID "sha256:..." not yet present on node...
Loading image: quay.io/cilium/cilium:v1.15.5
Image loaded successfully

Step 5 — Get the control plane IP
Cilium needs to know where the API server is because it's replacing kube-proxy:

kubectl get node idp-cluster-control-plane \
  -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}'

Step 6 — Install Cilium via Helm
Now paste your control plane IP into this command where it says PASTE_IP_HERE:

helm install cilium cilium/cilium \
  --version 1.15.5 \
  --namespace kube-system \
  --set kubeProxyReplacement=true \
  --set k8sServiceHost=PASTE_IP_HERE \
  --set k8sServicePort=6443 \
  --set routingMode=tunnel \
  --set tunnelProtocol=vxlan \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true \
  --set image.pullPolicy=IfNotPresent

FlagWhykubeProxyReplacement=true  >>  Cilium handles all service routing via eBPF — no iptables
k8sServiceHost    >>    API server IP — needed since kube-proxy is disabled
k8sServicePort=6443  >>  API server port — always 6443
routingMode=tunnel    >>    VXLAN overlay — works inside Docker (kind)
hubble.relay.enabled=true    >>    Enables Hubble backend for network flows
hubble.ui.enabled=true    >>    Enables Hubble browser UI
image.pullPolicy=IfNotPresent    >>    Use the pre-loaded image — don't re-pull

Step 7 — Watch Cilium pods start

# Watch Cilium pods come up in real time
kubectl get pods -n kube-system -w | grep cilium

Wait until you see all pods Running:
cilium-xxxxx   1/1   Running   0   60s
cilium-xxxxx   1/1   Running   0   60s
cilium-xxxxx   1/1   Running   0   60s
cilium-xxxxx   1/1   Running   0   60s
cilium-operator-xxxxx   1/1   Running   0   60s

Step 8 — Check nodes are now Ready
kubectl get nodes

All nodes should now show Ready:
NAME                        STATUS   ROLES           AGE
idp-cluster-control-plane   Ready    control-plane   5m
idp-cluster-worker          Ready    <none>          5m
idp-cluster-worker2         Ready    <none>          5m
idp-cluster-worker3         Ready    <none>          5m

Step 9 — Verify Cilium is healthy
cilium status

Expected output — everything should be green:

/¯¯\
 /¯¯\__/¯¯\    Cilium:             OK
 \__/¯¯\__/    Operator:           OK
 /¯¯\__/¯¯\    Envoy DaemonSet:    disabled
 \__/¯¯\__/    Hubble Relay:       OK
    \__/        ClusterMesh:        disabled

Deployment             cilium-operator    Desired: 1, Ready: 1/1
DaemonSet              cilium             Desired: 4, Ready: 4/4

Step 10 — Open Hubble UI

cilium hubble ui

This automatically opens your browser with a live network flow map. Right now it'll be mostly empty — but once we deploy workloads in Phase 2 you'll see traffic flowing between namespaces in real time. Great interview demo.

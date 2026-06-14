# Issue Summary — IDP Cluster Troubleshooting

---

## Issue 1: `kubectl apply` on kind-config.yaml

**Error:**
```
Error in configuration: context was not found for specified context: 134
```

**Cause:** `kind-config.yaml` is a kind cluster config, not a Kubernetes manifest. Cannot be applied with `kubectl apply`.

**Fix:**
```bash
# Correct command — use kind, not kubectl
kind create cluster --config k8s-idp/cluster-with-cilium/kind-config.yaml
```

---

## Issue 2: Docker Hub unauthorized when pulling kind node image

**Error:**
```
unauthorized: incorrect username or password
```

**Cause:** Docker client has stale or incorrect credentials stored for Docker Hub.

**Fix:**
```bash
# Clear bad credentials and re-login
docker logout
docker login
```

---

## Issue 3: cilium.tar.gz not in gzip format

**Error:**
```
gzip: stdin: not in gzip format
```

**Cause:** The `curl -s` flag silenced errors — the download failed silently and saved an error response (9 bytes of text) instead of the real archive.

**Fix:**
```bash
# Use --progress-bar instead of -s so you can see if download fails
ARCH=$(uname -m)
case $ARCH in
  x86_64)  ARCH="amd64" ;;
  aarch64) ARCH="arm64" ;;
esac

curl -L --progress-bar \
  "https://github.com/cilium/cilium-cli/releases/download/v0.16.10/cilium-linux-${ARCH}.tar.gz" \
  -o cilium.tar.gz

tar xzf cilium.tar.gz
sudo mv cilium /usr/local/bin/cilium
rm cilium.tar.gz
```

---

## Issue 4: `istioctl install` positional argument error

**Error:**
```
Error: accepts 0 arg(s), received 1
```

**Cause:** `istioctl install` does not accept a positional argument for the config file.

**Fix:**
```bash
# Use -f flag, not a positional argument
istioctl install -f k8s-idp/istio/minimal-profile.yaml
```

---

## Issue 5: `argocd: command not found`

**Cause:** ArgoCD CLI not installed on the machine.

**Fix:**
```bash
curl -sL -o /tmp/argocd \
  "https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"
chmod +x /tmp/argocd
sudo mv /tmp/argocd /usr/local/bin/argocd
```

---

## Issue 6: `argocd app sync --core` permission denied / configmap not found

**Error:**
```
configmap "argocd-cm" not found
rpc error: code = PermissionDenied
```

**Cause:** `--core` mode reads the current kubectl namespace. Default namespace is `default`, not `argocd`.

**Fix:**
```bash
# Option 1 — switch namespace context temporarily
kubectl config set-context --current --namespace=argocd
argocd app sync payments-istio --core
kubectl config set-context --current --namespace=default

# Option 2 — use API server instead (recommended)
kubectl port-forward svc/argocd-server -n argocd 8080:80 &
PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)
argocd login localhost:8080 --username admin --password "$PASS" --insecure
argocd app sync payments-istio
```

---

## Issue 7: Helm upgrade Cilium blocked by Gatekeeper webhook

**Error:**
```
failed calling webhook "check-ignore-label.gatekeeper.sh": dial tcp ...: connect: no route to host
```

**Cause:** Deadlock — Cilium networking is broken so Gatekeeper pods are unreachable, but Kubernetes calls the Gatekeeper webhook for every admission request (including Cilium's namespace creation). With `failurePolicy: Fail`, any webhook timeout blocks the upgrade.

**Root cause in Gatekeeper Helm install:** `validatingWebhookCheckIgnoreFailurePolicy` defaults to `Fail`.

**Immediate fix (break the deadlock):**
```bash
# Temporarily patch webhook to Ignore so Cilium upgrade can proceed
kubectl patch validatingwebhookconfiguration gatekeeper-validating-webhook-configuration \
  --type=json \
  -p='[{"op":"replace","path":"/webhooks/1/failurePolicy","value":"Ignore"}]'

# Upgrade Cilium
CP_IP=$(docker inspect idp-cluster-control-plane \
  --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
helm upgrade cilium cilium/cilium --version 1.19.4 -n kube-system \
  --reuse-values --set k8sServiceHost="$CP_IP"
```

**Permanent fix — upgrade Gatekeeper with correct flag:**
```bash
helm upgrade gatekeeper gatekeeper/gatekeeper \
  -n gatekeeper-system \
  --reuse-values \
  --set validatingWebhookCheckIgnoreFailurePolicy=Ignore
```

**Also add system namespaces to Gatekeeper Config** (`k8s-idp/platform/opa-gatekeeper/config.yaml`):
```yaml
apiVersion: config.gatekeeper.sh/v1alpha1
kind: Config
metadata:
  name: skip-ns
  namespace: gatekeeper-system
spec:
  match:
    - excludedNamespaces:
        - kube-system
        - kube-public
        - kube-node-lease
        - gatekeeper-system
      processes:
        - "*"
```

---

## Issue 8: Cilium upgrade fails with wrong control-plane IP after reboot

**Error:**
```
dial tcp 172.18.0.4:6443: connect: connection refused
```

**Cause:** Docker reassigns container IPs after a machine reboot. The control-plane node moved from `172.18.0.4` → `172.18.0.3`, but `k8sServiceHost` in Cilium still had the old IP.

**Diagnosis:**
```bash
# Get real current IP from Docker (authoritative)
docker inspect idp-cluster-control-plane \
  --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'

# Compare with what Kubernetes thinks (may be stale after reboot)
kubectl get node idp-cluster-control-plane \
  -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}'
```

**Fix — always get IP from Docker before upgrading Cilium:**
```bash
CP_IP=$(docker inspect idp-cluster-control-plane \
  --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')

helm upgrade cilium cilium/cilium --version 1.19.4 -n kube-system \
  --reuse-values --set k8sServiceHost="$CP_IP"
```

---

## Issue 9: Control-plane node NotReady after reboot (kubelet.conf stale IP)

**Symptom:**
```
NAME                        STATUS     ROLES
idp-cluster-control-plane   NotReady   control-plane
```

**Cause:** `/etc/kubernetes/kubelet.conf` inside the control-plane Docker container still has the old IP. The kubelet cannot reach the API server.

**Key distinction:**
| File | Location | Used by |
|------|----------|---------|
| `~/.kube/config` | Host machine | `kubectl` from your terminal |
| `/etc/kubernetes/kubelet.conf` | Inside Docker container | kubelet process inside the node |

**Diagnosis:**
```bash
# Check what IP kubelet is trying to reach
docker exec idp-cluster-control-plane journalctl -u kubelet --no-pager -n 10

# Check what IP is configured
docker exec idp-cluster-control-plane grep server /etc/kubernetes/kubelet.conf

# Only show errors
docker exec idp-cluster-control-plane \
  journalctl -u kubelet --no-pager -n 50 | grep "^.*E[0-9]"

# Only show warnings and errors
docker exec idp-cluster-control-plane \
  journalctl -u kubelet --no-pager -n 50 | grep -E " [EW][0-9]{4} "

# Follow live logs (like tail -f)
docker exec idp-cluster-control-plane \
  journalctl -u kubelet -f

# Logs since a specific time
docker exec idp-cluster-control-plane \
  journalctl -u kubelet --since "10 minutes ago" --no-pager

  # Search past logs for connection errors
docker exec idp-cluster-control-plane \
  journalctl -u kubelet --no-pager | grep "connection refused\|Unable to register\|Unable to contact"

# Search past logs for connection errors
docker exec idp-cluster-control-plane \
  journalctl -u kubelet --no-pager | grep "connection refused\|Unable to register\|Unable to contact"

kubectl get nodes
  → control-plane NotReady

journalctl -u kubelet -n 50 | grep "E[0-9]"
  → shows "connection refused to 172.18.0.4:6443"

grep server /etc/kubernetes/kubelet.conf
  → confirms wrong IP is hardcoded

sed -i to fix it → restart kubelet
  → node becomes Ready, logs go back to normal (what you saw)


```


**Fix:**
```bash
# Get correct current IP
CP_IP=$(docker inspect idp-cluster-control-plane \
  --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')

# Update kubelet.conf inside the container (replace old IP with new)
docker exec idp-cluster-control-plane \
  sed -i "s/172\.18\.0\.4:6443/${CP_IP}:6443/g" /etc/kubernetes/kubelet.conf

# Restart kubelet
docker exec idp-cluster-control-plane systemctl restart kubelet

# Verify node comes back Ready
kubectl get nodes
```

---

## General tip: After every machine reboot on a kind cluster

Docker reassigns IPs to kind node containers. Run these checks before doing anything else:

```bash
# 1. Get current IPs from Docker
docker network inspect kind | grep -A 3 '"Name"'

# 2. Update Cilium with correct control-plane IP
CP_IP=$(docker inspect idp-cluster-control-plane \
  --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
helm upgrade cilium cilium/cilium --version 1.19.4 -n kube-system \
  --reuse-values --set k8sServiceHost="$CP_IP"

# 3. Check and fix kubelet.conf if control-plane is NotReady
docker exec idp-cluster-control-plane grep server /etc/kubernetes/kubelet.conf
# If it shows a wrong IP, fix it:
docker exec idp-cluster-control-plane \
  sed -i "s/<OLD_IP>:6443/${CP_IP}:6443/g" /etc/kubernetes/kubelet.conf
docker exec idp-cluster-control-plane systemctl restart kubelet
```

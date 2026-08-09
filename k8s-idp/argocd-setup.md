# ArgoCD Setup

## Install

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

helm install argocd argo/argo-cd \
  --version 7.3.6 \
  --namespace argocd \
  --create-namespace \
  --set configs.params."server\.insecure"=true \
  --wait --timeout 10m
```

> `server.insecure=true` runs ArgoCD on plain HTTP (port 8080). SSL is terminated at the ingress/gateway level.

## Verify

```bash
kubectl get pods -n argocd
kubectl get cm argocd-cmd-params-cm -n argocd
```

---

## Initial Access

### Get the initial admin password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

> Delete this secret after you change the password:
> `kubectl delete secret argocd-initial-admin-secret -n argocd`

### Access the UI

**Option 1 — NodePort (recommended with Cilium)**

```bash
kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"NodePort"}}'
kubectl get svc argocd-server -n argocd   # note the NodePort for port 80
```

Then open: `http://<node-ip>:<nodeport>`

Node IPs: `kubectl get nodes -o wide`

**Option 2 — Port-forward**

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

> ⚠️ Port-forward may fail on clusters using Cilium kube-proxy replacement.
> See [Troubleshooting](#port-forward-fails-with-cilium-kube-proxy-replacement) below.

### Login via CLI

```bash
# With NodePort
argocd login <node-ip>:<nodeport> \
  --username admin \
  --password "<password>" \
  --insecure --plaintext

# With port-forward
argocd login localhost:8080 \
  --username admin \
  --password "<password>" \
  --insecure --plaintext
```

> Use `--plaintext` because the server runs in insecure (HTTP) mode.

---

## Repo Setup

```bash
# Set argocd as default namespace so CLI core-mode works
kubectl config set-context --current --namespace=argocd

# Add repo via secret (simplest — no CLI auth needed)
kubectl -n argocd create secret generic repo-ace-project-2026 \
  --from-literal=type=git \
  --from-literal=url=https://github.com/zinmoe-tech/ace-project-2026.git \
  --from-literal=username=zinmoe8988@gmail.com \
  --from-literal=password=<YOUR_GITHUB_PAT>

# Or via CLI after login
argocd repo add https://github.com/zinmoe-tech/ace-project-2026.git
```

### Remove a repo

```bash
# List repo secrets
kubectl get secrets -n argocd -l argocd.argoproj.io/secret-type=repository

# Delete by secret name
kubectl delete secret repo-ace-project-2026 -n argocd

# Or via CLI
argocd repo rm https://github.com/zinmoe-tech/ace-project-2026.git
```

> ⚠️ If the repo is private and apps still reference it, they will go into `Unknown/ComparisonError` after removal. Remove or pause apps first.

---

## Install ArgoCD CLI

```bash
curl -sL -o /tmp/argocd \
  "https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"

chmod +x /tmp/argocd
sudo mv /tmp/argocd /usr/local/bin/argocd

argocd version --client
```

---

## Troubleshooting

### Port-forward fails with Cilium kube-proxy replacement

**Symptom:**

```
# Variant 1 — wrong port (trying HTTPS when server is in insecure/HTTP mode)
error forwarding port 443 to pod ...: failed to connect to localhost:443 inside namespace ...:
  IPv4: dial tcp4 127.0.0.1:443: connect: connection refused
  IPv6: dial tcp6 [::1]:443: connect: connection refused

# Variant 2 — correct port but connection immediately reset
writeto tcp4 127.0.0.1:52768->127.0.0.1:8080: read: connection reset by peer
error: lost connection to pod
```

**What's happening step by step:**

1. `kubectl port-forward` opens a TCP listener on your local machine (e.g. `127.0.0.1:8080`).
2. When you connect to that local port, kubectl tunnels the traffic through the Kubernetes API server down to the kubelet on the node.
3. The kubelet connects to `localhost:<target-port>` **inside the pod's network namespace**.
4. With Cilium's kube-proxy replacement enabled, Cilium attaches eBPF programs at the socket level (`socketLB`). These intercept connections made inside pod namespaces and can redirect or drop them — including the kubelet's inbound tunnel connection.
5. The result: the connection is reset before your traffic ever reaches the ArgoCD process.

**Why it looks confusing:**

- The port-forward log shows `Handling connection for 8080` (the tunnel opened), then immediately `connection reset by peer` (Cilium dropped it inside the pod).
- The ArgoCD server itself is healthy — its own logs show successful gRPC calls, because those come through normal pod-to-pod networking, not through port-forward.
- Verify the server is actually listening: `kubectl exec -n argocd <pod> -- cat /proc/net/tcp6 | awk 'NR>1{print $2,$4}' | grep ' 0A'`
  - `1F90` (hex) = 8080 (decimal) → server is up, port-forward is the problem.

**Also check — wrong protocol error:**

If ArgoCD is running in insecure mode (`server.insecure=true`) but you port-forward to port `443` and connect with HTTPS, you get a TLS negotiation failure. Always forward to port `80` (HTTP) and use `--plaintext` in the CLI:

```bash
# Wrong — forwards to HTTPS port on a plain-HTTP server
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Correct — forwards to HTTP port
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

**Fix: expose via NodePort, then proxy to localhost**

`kubectl port-forward` to both the service AND the pod fail — Cilium intercepts connections inside the pod's network namespace regardless of which resource you forward to. The fix is to use NodePort (which goes through Cilium's normal eBPF datapath) and then proxy that to localhost.

**Step 1 — expose as NodePort**

```bash
kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"NodePort"}}'

# Get the NodePort assigned to HTTP (port 80) and a node IP
NODE_PORT=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
echo "$NODE_IP:$NODE_PORT"
```

At this point you can already access ArgoCD directly via `http://<node-ip>:<nodeport>`. If you're happy with that, skip Step 2.

**Step 2 — forward localhost:8080 → NodePort (if you need `localhost`)**

Option A — `socat` (persistent, no sudo needed after install):

```bash
sudo apt-get install -y socat

# Run in background — stays up as long as the shell is open
socat TCP-LISTEN:8080,reuseaddr,fork TCP:$NODE_IP:$NODE_PORT &

# Kill it later with:
pkill socat
```

Option B — iptables DNAT (survives process restarts, cleared on reboot):

```bash
sudo iptables -t nat -A OUTPUT -p tcp -d 127.0.0.1 --dport 8080 \
  -j DNAT --to-destination $NODE_IP:$NODE_PORT

# Verify rule was added
sudo iptables -t nat -L OUTPUT -n --line-numbers

# Remove it later (use the line number from above, e.g. 1)
sudo iptables -t nat -D OUTPUT 1
```

**Step 3 — access via localhost**

```bash
# UI
http://localhost:8080

# CLI login
argocd login localhost:8080 \
  --username admin \
  --password <pass> \
  --insecure --plaintext
```

---

### Forgot / reset admin password

The `argocd-initial-admin-secret` only holds the *initial* password. If you changed it and forgot it, reset via the `argocd-secret`:

```bash
# Generate a new bcrypt hash
NEW_HASH=$(python3 -c "
import bcrypt
print(bcrypt.hashpw(b'<new-password>', bcrypt.gensalt(rounds=10)).decode())
" | sed 's/\$2b/\$2a/')

# Patch the secret
HASH_B64=$(echo -n "$NEW_HASH" | base64 -w0)
TIME_B64=$(date +%FT%TZ | base64 -w0)

kubectl patch secret argocd-secret -n argocd \
  -p "{\"data\":{\"admin.password\":\"$HASH_B64\",\"admin.passwordMtime\":\"$TIME_B64\"}}"

# Restart the server to pick up the change
kubectl rollout restart deployment argocd-server -n argocd
```

---

### Application stuck in Terminating

```bash
kubectl delete application <app-name> -n argocd

# If it hangs, strip the finalizer
kubectl patch application <app-name> -n argocd \
  -p '{"metadata":{"finalizers":null}}' --type merge
```

---

### `argocd-cm not found` when running `argocd app sync --core`

**Cause:** `--core` mode looks for `argocd-cm` in the *current* namespace. If your context is `default`, it fails.

**Fix:**

```bash
kubectl config set-context --current --namespace=argocd
argocd app sync <app-name> --core
```

---

### Helm install fails (redis job leftover)

```bash
helm uninstall argocd -n argocd
kubectl -n argocd delete job argocd-redis-secret-init --ignore-not-found

helm install argocd argo/argo-cd \
  --version 7.3.6 \
  --namespace argocd \
  --create-namespace \
  --set configs.params."server\.insecure"=true \
  --wait --timeout 10m
```

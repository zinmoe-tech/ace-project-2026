# Add the helm repo

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Install ArgoCD 

helm install argocd argo/argo-cd \
  --version 7.3.6 \
  --namespace argocd \
  --create-namespace \
  --set configs.params."server\.insecure"=true \
  --wait

# Verify Pods

kubectl get pods -n argocd

####
```
NAME: argocd
LAST DEPLOYED: Thu Jun  4 09:09:52 2026
NAMESPACE: argocd
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
In order to access the server UI you have the following options:

1. kubectl port-forward service/argocd-server -n argocd 8080:443

    and then open the browser on http://localhost:8080 and accept the certificate

2. enable ingress in the values file `server.ingress.enabled` and either
      - Add the annotation for ssl passthrough: https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/#option-1-ssl-passthrough
      - Set the `configs.params."server.insecure"` in the values file and terminate SSL at your ingress: https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/#option-2-multiple-ingress-objects-and-hosts


After reaching the UI the first time you can login with username: admin and the random password generated during the installation. You can find the password by running:

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

(You should delete the initial secret afterwards as suggested by the Getting Started Guide: https://argo-cd.readthedocs.io/en/stable/getting_started/#4-login-using-the-cli)

```

# Get the admin password

kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo

# Port-forward 

kubectl port-forward svc/argocd-server -n argocd 8080:443

# Create secret for ArgoCD

kubectl -n argocd create secret generic repo-ace-project-2026 \
  --from-literal=type=git \
  --from-literal=url=https://github.com/zinmoe-tech/ace-project-2026.git \
  --from-literal=username=zinmoe8988@gmail.com \
  --from-literal=password=<YOUR_GITHUB_PAT>

# Login via CLI
argocd login localhost:8080 \
  --username admin \
  --password "$(kubectl -n argocd get secret argocd-initial-admin-secret \
    -o jsonpath='{.data.password}' | base64 -d)" \
  --insecure

# Add your repo
argocd repo add https://github.com/zinmoe-tech/ace-project-2026.git

# Output

repository 'https://github.com/YOUR_USERNAME/k8s-idp' added


###kubectl delete applications --all -n argocd --cascade=orphan

kubectl delete application root-app -n argocd

If it hangs (sits there, doesn't return), it's the finalizer. Ctrl+C and go to Step 2.

Step 2 — Remove the finalizer (this is what unblocks it)

The resources-finalizer.argocd.argoproj.io is holding it in Terminating. Strip it:


kubectl patch application root-app -n argocd \
  -p '{"metadata":{"finalizers":null}}' --type merge

The Application disappears immediately after this.

Step 3 — Confirm

kubectl get applications -n argocd

## How to remove git from ArgoCD

Depends on how it was added — and you added it as a Kubernetes secret (repo-ace-project-2026), so the cleanest way is just to delete that secret.

List the repo creds first

kubectl get secrets -n argocd -l argocd.argoproj.io/secret-type=repository
Remove it — two equivalent ways
A. Delete the secret (matches how you added it — no CLI/core-mode hassle):


kubectl delete secret repo-ace-project-2026 -n argocd
B. Via the argocd CLI (if you prefer, but it needs the core-mode namespace set):


kubectl config set-context --current --namespace=argocd
argocd repo rm https://github.com/zinmoe-tech/ace-project-2026.git
Either one removes the repo registration. A is simpler and avoids the argocd-cm not found core-mode errors you kept hitting.

⚠️ Heads-up before you remove it
That repo is the source for all your Applications (root-app and children). If you delete the credential while the apps still exist and the repo is private, their next sync/refresh will fail with authentication required: Repository not found — they'll go Unknown/ComparisonError. So either:

Remove the apps first, or
Only remove the repo if you're re-adding it (e.g., rotating the leaked token).
Verify it's gone

kubectl get secrets -n argocd -l argocd.argoproj.io/secret-type=repository
# repo-ace-project-2026 should no longer be listed
Want me to run option A for you?


#### Install ArgoCD in client

curl -sL -o /tmp/argocd \
  "https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"

chmod +x /tmp/argocd
sudo mv /tmp/argocd /usr/local/bin/argocd

argocd version --client

### For CM error

kubectl get pods -n argocd 

kubectl get configmap argocd-cm -n argocd

kubectl config view --minify --output 'jsonpath={..namespace}'

kubectl config set-context --current --namespace=argocd
argocd app sync payments-istio --core

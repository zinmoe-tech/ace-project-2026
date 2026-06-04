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
  --from-literal=password=ghp_REPLACE_WITH_YOUR_TOKEN   # never commit a real token

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
## Create required directory
mkdir -p k8s-idp/{clusters/prod/{namespaces,cluster-wide,argocd},platform/{ingress-nginx,cert-manager,external-secrets,opa-gatekeeper,karpenter,observability/{prometheus-stack,loki-stack,tempo,slo-alerts}},apps/{team-a,team-b}} && touch k8s-idp/apps/team-a/{deployment.yaml,hpa.yaml,networkpolicy.yaml,externalsecret.yaml}

## Verification
$ find k8s-idp -type d | sort
$ tree k8s-idp

### Installation ArgoCD
## Step 1 — Install ArgoCD (Package manager for Kubernetes)
# Add the ArgoCD Helm repo
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Install ArgoCD
helm install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --set configs.params."server\.insecure"=true \
  --wait

# Confirm all pods are running
kubectl get pods -n argocd

## Step 2 — Get the admin password
$ kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d; echo

# reset admin password to a known bcrypt hash (example sets it to "newpassword")
argocd account update-password --core   # interactive, if you know the current one


## Step 3 — Access the UI
Run this in a dedicated terminal — keep it open
$ kubectl port-forward svc/argocd-server -n argocd 8080:443

## Step 4 — Connect your GitHub repo to ArgoCD
Before applying root-app, ArgoCD needs access to your repo. Run this
# Install ArgoCD CLI (Command-line client for ArgoCD)
brew install argocd

# Login via CLI
argocd login localhost:8080 \
  --username admin \
  --password <ADMIN_PASSWORD> \
  --insecure

# Add your repo (public repo — no credentials needed)
argocd repo add https://github.com/zinmoe-tech/ace-project-2026.git --username zinmoe8988@gmail.com --password <YOUR_GITHUB_PAT>

# If your repo is private, add credentials
argocd repo add https://github.com/zinmoe-tech/k8s-idp \
  --username zinmoe-tech \
  --password <YOUR_GITHUB_PAT>   # Personal Access Token from github.com/settings/tokens

Verification
$ argocd repo list

## Step 5 — Apply the root app

cd /home/test/Desktop/ace-project-2026
git add k8s-idp/clusters/prod/argocd/*.yaml
git commit -m "fix(argocd): correct repoURL to ace-project-2026 and prefix paths with k8s-idp/"
git push origin main

$ kubectl apply -f clusters/prod/argocd/root-app.yaml

## Step 6 — Watch ArgoCD sync
Watch apps appear and sync in real time
$ watch kubectl get applications -n argocd

NAME                   SYNC STATUS   HEALTH STATUS
root-app               Synced        Healthy
platform-namespaces    Synced        Healthy
team-a-apps            OutOfSync     Missing
team-b-apps            OutOfSync     Missing

## Step 7 — Verify namespaces were created
# Namespaces should exist
$ kubectl get namespaces | grep team

# ResourceQuotas applied
$ kubectl get resourcequota -A | grep team

# LimitRanges applied
$ kubectl get limitrange -A | grep team

## Output
team-a   Active
team-b   Active

team-a   team-a-quota   ...
team-b   team-b-quota   ...

team-a   team-a-limitrange
team-b   team-b-limitrange

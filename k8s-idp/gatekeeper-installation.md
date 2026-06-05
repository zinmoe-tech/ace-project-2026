helm repo add gatekeeper \
  https://open-policy-agent.github.io/gatekeeper/charts
helm repo update

helm install gatekeeper gatekeeper/gatekeeper \
  --namespace gatekeeper-system \
  --create-namespace \
  --wait

kubectl get pods -n gatekeeper-system

# 2. Force Argo CD to pull the new commit immediately (instead of waiting ~3 min)
kubectl -n argocd annotate application gatekeeper-policies \
  argocd.argoproj.io/refresh=hard --overwrite
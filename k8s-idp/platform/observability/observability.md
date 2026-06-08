# Step 1 — Add Helm repos

# Prometheus community charts
helm repo add prometheus-community \
  https://prometheus-community.github.io/helm-charts

# Grafana charts (for Loki)
helm repo add grafana \
  https://grafana.github.io/helm-charts

helm repo update

# Step 2 — Create the values file for kube-prometheus-stack

This is the most important file — it configures Prometheus, Grafana, and Alertmanager together:

FILE: platform/observability/prometheus-stack/values.yaml

# Step 3 — Create the ArgoCD Application for the stack

FILE: clusters/prod/argocd/prometheus-stack-app.yaml

# Step 4 — Commit and push

# Step 5 - Sync

argocd app sync root-app --grpc-web





Fix — finish the stuck delete, then re-bootstrap

cd /home/test/Desktop/ace-project-2026

# 1. remove the finalizer so the wedged deletion completes (root-app finally goes away)
kubectl patch application root-app -n argocd \
  -p '{"metadata":{"finalizers":null}}' --type merge

# 2. confirm it's gone
kubectl get applications -n argocd

# 3. re-apply root-app from Git -> it recreates ALL children (platform-namespaces, team-a/b, etc.)
kubectl apply -f k8s-idp/clusters/prod/argocd/root-app.yaml

# 4. watch them come back
kubectl get applications -n argocd
After step 3, root-app re-syncs and rebuilds the whole tree from Git — platform-namespaces, team-a-apps, team-b-apps reappear (and cluster-wide / gatekeeper-policies, which survived, get re-adopted).

Note: removing the finalizer orphans any resources root-app still managed (they stay), and re-applying re-adopts them — so your namespaces/workloads aren't wiped.


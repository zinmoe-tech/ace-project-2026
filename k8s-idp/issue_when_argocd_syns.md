The issues (there were 3 distinct ones)
Issue 1 — configmap "argocd-cm" not found
You ran argocd app sync ... --core. In --core mode there's no argocd-server; the CLI reads argocd-cm from your current kubeconfig namespace. Yours was default, so it looked in the wrong place. Recurs after every cluster rebuild because the namespace resets.

Issue 2 — another operation is already in progress
The app has automated + selfHeal sync. It kept auto-retrying a failing sync, holding the operation lock — so your manual sync was rejected.

Issue 3 (the real bug) — namespaces "team-a" not found
In teams.yaml, the --- document separator between the team-a and team-b Namespaces was commented out (# ---). YAML then parsed both as one document with duplicate keys, and the last one (team-b) won — so only team-b was ever created. The RBAC RoleBindings targeting team-a then failed because that namespace didn't exist.

Step-by-step solution (what we did)
Fixed the namespace context so --core finds its config:

kubectl config set-context --current --namespace=argocd
Cleared the stuck operation lock:

kubectl -n argocd patch application platform-namespaces --type=merge -p '{"operation":null}'
Fixed the YAML bug — restored the live --- separator at line 52 of teams.yaml (so team-a and team-b are two separate documents). Verified with:

kubectl apply --dry-run=client -f k8s-idp/clusters/prod/namespaces/teams.yaml
# → namespace/team-a created, namespace/team-b configured  ✅
Committed + pushed the fix (commit 3e22bfc) — required because Argo CD syncs from GitHub, not your local folder.
Hard-refreshed Argo to pull the new commit:

kubectl -n argocd annotate application platform-namespaces argocd.argoproj.io/refresh=hard --overwrite
→ app went Synced + Healthy, team-a created, team-a Roles/RoleBindings applied. ✅
Remaining steps (to finish your two-team goal)
Right now team-a RBAC works; team-b has a namespace but no RBAC (team-b-rbac.yaml is still 100% commented), and the cross-team view bindings don't exist yet.

Uncomment team-b-rbac.yaml → team-b gets its developer + viewer roles and bindings.
Add two cross-team viewer RoleBindings:
team-a-developers → bound to viewer role in team-b (team-a views team-b)
team-b-developers → bound to viewer role in team-a (team-b views team-a)
Commit + push, then it auto-syncs.
Lessons to avoid repeats
After any kind create cluster + Argo install: immediately run kubectl config set-context --current --namespace=argocd.
When removing resources from a multi-doc YAML, keep the --- separators between the docs you're keeping.
Editing files locally isn't enough — GitOps only applies what's pushed to Git.
Want me to do steps 6 and 7 now (edit team-b-rbac.yaml + add the cross-team bindings) so you just review, commit, and push?
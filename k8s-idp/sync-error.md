Most likely it's the apply-ordering problem I flagged when we turned on recursion: now Argo CD reads both templates/ and contraints/ together, but a Constraint can't be created until its ConstraintTemplate has generated the matching CRD. On the first sync the constraints fail with something like no matches for kind "K8sRequireResourceLimits" in version "constraints.gatekeeper.sh/v1beta1" → the app shows SyncFailed.

Step 1 — Confirm the exact error

# the overall sync error
kubectl -n argocd get application gatekeeper-policies \
  -o jsonpath='{.status.operationState.message}{"\n"}'

# per-resource status (which ones failed)
kubectl -n argocd get application gatekeeper-policies \
  -o jsonpath='{range .status.resources[*]}{.kind}/{.name}  sync={.status}  health={.health.status}{"\n"}{end}'
If the failing items are the Constraints (not the Templates), it's the ordering issue.

Step 2 — Fix the ordering with sync-waves
Add these annotations so templates apply first, constraints second:

On each ConstraintTemplate (templates/*.yaml):

metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "1"
On each Constraint (contraints/*.yaml):

metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "2"
Then commit + push, and refresh:


kubectl -n argocd annotate application gatekeeper-policies argocd.argoproj.io/refresh=hard --overwrite
Step 3 — Quick alternative (no edits): just sync twice
The templates create the CRDs on the first pass, so a second sync makes the constraints succeed:


argocd app sync gatekeeper-policies        # 1st: templates apply, constraints may fail
argocd app sync gatekeeper-policies        # 2nd: constraints now succeed
(Or enable auto-retry in the app's syncPolicy.retry.)

But before assuming — run Step 1 first, because the failure could also be a different cause (e.g., a malformed ConstraintTemplate, or the contraints typo folder containing a bad path). Paste me the output of Step 1 and I'll tell you exactly which fix applies. Want me to run Step 1 for you?
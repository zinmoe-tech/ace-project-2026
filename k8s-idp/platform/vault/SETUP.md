# Vault + Vault Secrets Operator — Setup Procedure

This directory holds the **GitOps-managed** Vault Secrets Operator (VSO) custom
resources. Vault itself (server + operator) is installed and bootstrapped
**manually** because `vault operator init`/`unseal` cannot be expressed in Git.

```
platform/vault/
  01-vault-connection.yaml   VaultConnection "idp-vault"  — how VSO reaches Vault
  02-vault-auth.yaml         VaultAuth "idp-auth"         — k8s auth, role "idp"
  03-grafana-secret.yaml     VaultStaticSecret → Secret grafana-admin (monitoring)
  04-argocd-repo-secret.yaml VaultStaticSecret → Secret repo-ace-project-2026 (argocd)
```
Deployed by the Argo CD app `clusters/prod/argocd/vault-secrets-app.yaml`.

---

## Architecture

```
Vault (standalone + Raft, ns: vault)
   ▲  kubernetes auth (role "idp", SA vault/default)
   │
VaultConnection idp-vault ──► VaultAuth idp-auth (allowedNamespaces: monitoring, argocd)
                                   ▲                 ▲
                 vaultAuthRef: vault/idp-auth        │
                                   │                 │
       VaultStaticSecret grafana-admin     VaultStaticSecret repo-ace-project-2026
         (ns monitoring)                       (ns argocd)
                 │                                   │
                 ▼                                   ▼
       Secret grafana-admin                Secret repo-ace-project-2026
       (Grafana admin.existingSecret)      (label secret-type=repository)
```

---

## Step 1 — Install Vault (standalone + Raft) and VSO

```bash
helm repo add hashicorp https://helm.releases.hashicorp.com && helm repo update

helm install vault hashicorp/vault -n vault --create-namespace \
  --set server.ha.enabled=true \
  --set server.ha.raft.enabled=true \
  --set server.ha.replicas=1

helm install vault-secrets-operator hashicorp/vault-secrets-operator -n vault --wait
```
`vault-0` will stay `0/1` (sealed) until Step 2.

## Step 2 — Initialize + unseal

> ⚠️ Standalone + Raft is **not** auto-unsealed. After every host/pod restart
> you must re-run the unseal loop below. Keep `vault-init.json` safe — it holds
> the root token and unseal keys. It is git-ignored.

```bash
kubectl -n vault exec vault-0 -- vault operator init \
  -key-shares=3 -key-threshold=3 -format=json > vault-init.json

for k in $(jq -r '.unseal_keys_b64[0,1,2]' vault-init.json); do
  kubectl -n vault exec vault-0 -- vault operator unseal "$k"
done
kubectl -n vault get pod vault-0   # → 1/1 Running
```

## Step 3 — Configure Vault (KV, auth, policy, role) + seed secrets

```bash
ROOT=$(jq -r .root_token vault-init.json)
kubectl -n vault exec -i vault-0 -- sh -c "
  export VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=$ROOT
  vault secrets enable -path=secret kv-v2 || true

  # #1 Grafana admin credentials
  vault kv put secret/grafana admin-user=admin admin-password='ChangeMe-Strong-123!'

  # #2 Argo CD repository credential (GitHub PAT)
  vault kv put secret/argocd type=git \
    url=https://github.com/zinmoe-tech/ace-project-2026.git \
    username=zinmoe8988@gmail.com password='<YOUR_GITHUB_PAT>'

  # Kubernetes auth so VSO can log in
  vault auth enable kubernetes || true
  vault write auth/kubernetes/config kubernetes_host=https://kubernetes.default.svc:443

  # Read-only policy for the two paths
  printf 'path \"secret/data/grafana\" { capabilities=[\"read\"] }\npath \"secret/data/argocd\" { capabilities=[\"read\"] }\n' \
    | vault policy write idp-read -

  # Role binding the VSO login SA (vault/default) to the policy
  vault write auth/kubernetes/role/idp \
    bound_service_account_names=default \
    bound_service_account_namespaces=vault \
    policy=idp-read ttl=1h
"
```

## Step 4 — Commit + push the GitOps resources

Argo CD applies the VSO CRs (this directory) once pushed:

```bash
git add k8s-idp/platform/vault \
        k8s-idp/clusters/prod/argocd/vault-secrets-app.yaml \
        k8s-idp/platform/observability/prometheus-stack/values.yaml
git commit -m "feat: source Grafana password and Argo repo PAT from Vault via VSO"
git push origin main
argocd app sync vault-secrets --core
```

## Step 5 — Verify

```bash
# VSO custom resources report Valid=True
kubectl -n monitoring get vaultstaticsecret grafana-admin
kubectl -n argocd      get vaultstaticsecret repo-ace-project-2026

# Native Secrets were materialized from Vault
kubectl -n monitoring get secret grafana-admin -o jsonpath='{.data.admin-password}' | base64 -d; echo
kubectl -n argocd      get secret repo-ace-project-2026 -l argocd.argoproj.io/secret-type=repository

# Grafana now consumes the Vault-sourced secret (re-sync prometheus-stack if already running)
argocd app sync prometheus-stack --core
```

---

## Rotation

Change a value in Vault and VSO re-syncs the k8s Secret within `refreshAfter` (30s):

```bash
ROOT=$(jq -r .root_token vault-init.json)
kubectl -n vault exec -i vault-0 -- sh -c \
  "export VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=$ROOT; \
   vault kv put secret/grafana admin-user=admin admin-password='NewStrongPass!'"
```

## Troubleshooting

| Symptom | Cause / Fix |
|---|---|
| `vault-0` stuck `0/1` | Sealed — run the Step 2 unseal loop (also needed after every restart). |
| VaultStaticSecret `Valid=False`, permission denied | Vault role/policy not applied, or path mismatch — re-run Step 3. |
| VSO can't use idp-auth from monitoring/argocd | Namespace missing from `allowedNamespaces` in 02-vault-auth.yaml. |
| Secret not created | Check VSO controller logs: `kubectl -n vault logs deploy/vault-secrets-operator-controller-manager`. |

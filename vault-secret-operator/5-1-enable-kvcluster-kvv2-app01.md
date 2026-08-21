# kv-v2 secrets engine for `kv-cluster`, and there are 5 apps running on different namespaces `such as kvcluster-app01-ns, kvcluster-app02-ns, kvcluster-app03-ns, etc etc etc`

# Enable secrets engine at the path `kvcluster-kvv2`
vault secrets enable -version=2 -path=kvcluster-kvv2 kv

# app01
vault kv put kvcluster-kvv2/app01/creds username='app01' password='supersecretpasswordv1'
vault kv get kvcluster-kvv2/app01/creds

# DO NOT FORGET `/data` in the policy
vault policy write kvcluster-kvv2-app01-policy - <<EOF
path "kvcluster-kvv2/data/app01/creds" {
  capabilities = ["read"]
}
EOF

# before `VSO` can sync secrets from `Vault to Kubernetes`, it needs `a VAULT ROLE to authenticate with`.
# The policy attached the role permits access to the KV secrets engine created in the previous section.

# `kvcluster-kvv2-app01-vault-role` vault role

vault write auth/kvcluster-k8s-auth/role/kvcluster-kvv2-app01-vault-role \
bound_service_account_names=kvcluster-app01-sa \
bound_service_account_namespaces=kvcluster-app01-ns \
policies=kvcluster-kvv2-app01-policy \
audience=app01 \
ttl=1h

vault read auth/kvcluster-k8s-auth/role/kvcluster-kvv2-app01-vault-role

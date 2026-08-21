# app03
vault kv put kvcluster-kvv2/app03/creds username='app03' password='supersecretpasswordv1'
vault kv get kvcluster-kvv2/app03/creds

# DO NOT FORGET `/data` in the policy
vault policy write kvcluster-kvv2-app03-policy - <<EOF
path "kvcluster-kvv2/data/app03/creds" {
  capabilities = ["read"]
}
EOF

# before `VSO` can sync secrets from `Vault to Kubernetes`, it needs `a VAULT ROLE to authenticate with`.
# The policy attached the role permits access to the KV secrets engine created in the previous section.

# `kvcluster-kvv2-app03-vault-role` vault role

vault write auth/kvcluster-k8s-auth/role/kvcluster-kvv2-app03-vault-role \
bound_service_account_names=kvcluster-app03-sa \
bound_service_account_namespaces=kvcluster-app03-ns \
policies=kvcluster-kvv2-app03-policy \
audience=app03 \
ttl=1h

vault read auth/kvcluster-k8s-auth/role/kvcluster-kvv2-app03-vault-role


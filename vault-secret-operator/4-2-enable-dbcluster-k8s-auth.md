
export K8S_URL_dbcluster=https://172.18.0.2:6443

# verify communication between `vault-oss-cluster` and `kubernetes api`
docker exec -it vault-oss-cluster sh
apk add curl
curl -k https://172.18.0.3:6443/healthz
curl -k https://172.18.0.5:6443/healthz
curl -k https://172.18.0.7:6443/healthz

# enable vault k8s auth method and configure for `db-cluster`

vault auth enable -path=dbcluster-k8s-auth kubernetes

vault write auth/dbcluster-k8s-auth/config \
  kubernetes_host="$K8S_URL_dbcluster" \
  kubernetes_ca_cert=@dbcluster_ca.crt \
  token_reviewer_jwt="$VAULTSA_JWT_TOKEN_dbcluster" \
  disable_local_ca_jwt=false   # true or false both OK when vault is runnning on a VM, default value is false
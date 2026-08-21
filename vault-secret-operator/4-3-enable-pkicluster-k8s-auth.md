
export K8S_URL_pkicluster=https://172.18.0.6:6443

# verify communication between `vault-oss-cluster` and `kubernetes api`
docker exec -it vault-oss-cluster sh
apk add curl
curl -k https://172.18.0.3:6443/healthz
curl -k https://172.18.0.5:6443/healthz
curl -k https://172.18.0.7:6443/healthz

# enable vault k8s auth method and configure for `pki-cluster`

vault auth enable -path=pkicluster-k8s-auth kubernetes

vault write auth/pkicluster-k8s-auth/config \
  kubernetes_host="$K8S_URL_pkicluster" \
  kubernetes_ca_cert=@pkicluster_ca.crt \
  token_reviewer_jwt="$VAULTSA_JWT_TOKEN_pkicluster" \
  disable_local_ca_jwt=false   # true or false both OK when vault is runnning on a VM, default value is false
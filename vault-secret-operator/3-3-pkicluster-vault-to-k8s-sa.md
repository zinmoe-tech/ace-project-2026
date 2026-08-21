# `pkicluster-vault-to-k8s-sa` Service Account in `pkicluster-vaultconn` Namespace

kubectl --context pki-cluster create -f - <<EOF
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: pkicluster-vault-to-k8s-sa #serviceaccount
  namespace: pkicluster-vaultconn
---
EOF

kubectl --context pki-cluster create -f - <<EOF
---
apiVersion: v1
kind: Secret
metadata:
  name: pkicluster-vault-to-k8s-sa-secret #secret
  namespace: pkicluster-vaultconn
  annotations:
    kubernetes.io/service-account.name: pkicluster-vault-to-k8s-sa
type: kubernetes.io/service-account-token
---
EOF


# STEP 2 - Create a k8s CLUSTERROLE for the `pkicluster-vault-to-k8s-sa` service account to allow access to the Kubernetes API.
* We don't need to create a `clusterrole` `system:auth-delegator` - because it is already with kubernetes cluster.
* So we only need to create `clusterrolebinding` as below.


kubectl --context pki-cluster create -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: pkicluster-vault-to-k8s-sa-tokenreview-role
  namespace: pkicluster-vaultconn # not required coz ClusterRoleBinding is not NS bound
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
  - kind: ServiceAccount
    name: pkicluster-vault-to-k8s-sa
    namespace: pkicluster-vaultconn
EOF


=============================

# for `pki-cluster`

VAULTSA_SECRET_pkicluster=$(kubectl get secret --namespace pkicluster-vaultconn pkicluster-vault-to-k8s-sa-secret --context pki-cluster --output json | jq -r '.data') && echo $VAULTSA_SECRET_pkicluster | jq

# extract the `ca.crt` value

echo $VAULTSA_SECRET_pkicluster | jq -r '."ca.crt"' | base64 -d > pkicluster_ca.crt

# extract the `token` value
VAULTSA_JWT_TOKEN_pkicluster=$(echo $VAULTSA_SECRET_pkicluster | jq -r '.token' | base64 -d) && echo $VAULTSA_JWT_TOKEN_pkicluster
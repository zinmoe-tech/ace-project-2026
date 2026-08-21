# `dbcluster-vault-to-k8s-sa` Service Account in `dbcluster-vaultconn` Namespace

kubectl --context db-cluster create -f - <<EOF
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: dbcluster-vault-to-k8s-sa #serviceaccount
  namespace: dbcluster-vaultconn
---
EOF

kubectl --context db-cluster create -f - <<EOF
---
apiVersion: v1
kind: Secret
metadata:
  name: dbcluster-vault-to-k8s-sa-secret #secret
  namespace: dbcluster-vaultconn
  annotations:
    kubernetes.io/service-account.name: dbcluster-vault-to-k8s-sa
type: kubernetes.io/service-account-token
---
EOF


# STEP 2 - Create a k8s CLUSTERROLE for the `dbcluster-vault-to-k8s-sa` service account to allow access to the Kubernetes API.
* We don't need to create a `clusterrole` `system:auth-delegator` - because it is already with kubernetes cluster.
* So we only need to create `clusterrolebinding` as below.


kubectl --context db-cluster create -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: dbcluster-vault-to-k8s-sa-tokenreview-role
  namespace: dbcluster-vaultconn # not required coz ClusterRoleBinding is not NS bound
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
  - kind: ServiceAccount
    name: dbcluster-vault-to-k8s-sa
    namespace: dbcluster-vaultconn
EOF


==================================

# for `db-cluster`

VAULTSA_SECRET_dbcluster=$(kubectl get secret --namespace dbcluster-vaultconn dbcluster-vault-to-k8s-sa-secret --context db-cluster --output json | jq -r '.data') && echo $VAULTSA_SECRET_dbcluster | jq

# extract the `ca.crt` value

echo $VAULTSA_SECRET_dbcluster | jq -r '."ca.crt"' | base64 -d > dbcluster_ca.crt

# extract the `token` value
VAULTSA_JWT_TOKEN_dbcluster=$(echo $VAULTSA_SECRET_dbcluster | jq -r '.token' | base64 -d) && echo $VAULTSA_JWT_TOKEN_dbcluster


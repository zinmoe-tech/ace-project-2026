# `kvcluster-vault-to-k8s-sa` Service Account in `kvcluster-vaultconn` Namespace

kubectl --context kv-cluster create -f - <<EOF
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: kvcluster-vault-to-k8s-sa #serviceaccount
  namespace: kvcluster-vaultconn
---
EOF

kubectl --context kv-cluster create -f - <<EOF
---
apiVersion: v1
kind: Secret
metadata:
  name: kvcluster-vault-to-k8s-sa-secret #secret
  namespace: kvcluster-vaultconn
  annotations:
    kubernetes.io/service-account.name: kvcluster-vault-to-k8s-sa
type: kubernetes.io/service-account-token
---
EOF


# STEP 2 - Create a k8s CLUSTERROLE for the `kvcluster-vault-to-k8s-sa` service account to allow access to the Kubernetes API.
* We don't need to create a `clusterrole` `system:auth-delegator` - because it is already with kubernetes cluster.
* So we only need to create `clusterrolebinding` as below.

kubectl --context kv-cluster create -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kvcluster-vault-to-k8s-sa-tokenreview-role
  namespace: kvcluster-vaultconn # not required coz ClusterRoleBinding is not NS bound
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
  - kind: ServiceAccount
    name: kvcluster-vault-to-k8s-sa
    namespace: kvcluster-vaultconn
EOF

=============================================

# for `kv-cluster`

VAULTSA_SECRET_kvcluster=$(kubectl get secret --namespace kvcluster-vaultconn kvcluster-vault-to-k8s-sa-secret --context kv-cluster --output json | jq -r '.data') && echo $VAULTSA_SECRET_kvcluster | jq

# extract the `ca.crt` value

echo $VAULTSA_SECRET_kvcluster | jq -r '."ca.crt"' | base64 -d > kvcluster_ca.crt

# extract the `token` value
VAULTSA_JWT_TOKEN_kvcluster=$(echo $VAULTSA_SECRET_kvcluster | jq -r '.token' | base64 -d) && echo $VAULTSA_JWT_TOKEN_kvcluster


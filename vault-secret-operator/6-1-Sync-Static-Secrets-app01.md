# before `VSO` can sync secrets from `Vault to Kubernetes`, it needs `a VAULT ROLE to authenticate with`.
# The policy attached the role permits access to the KV secrets engine created in the previous section.

# Create a k8s namespace and serviceaccount to deploy the app
kubectl create ns kvcluster-app01-ns --context kv-cluster
kubectl create sa kvcluster-app01-sa -n kvcluster-app01-ns --context kv-cluster

kubectl --context kv-cluster apply -f - <<EOF
---
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultAuth
metadata:
  name: vaultauth-kvcluster-app01
  namespace: kvcluster-app01-ns
spec:
  vaultConnectionRef: kvcluster-vaultconn/kvcluster-vault-connection
  method: kubernetes
  mount: kvcluster-k8s-auth
  allowedNamespaces:
    - kvcluster-app01-ns
  kubernetes:
    role: kvcluster-kvv2-app01-vault-role #vaultrole
    serviceAccount: kvcluster-app01-sa
    audiences:
      - app01
---
EOF

# verify
kubectl describe vaultauth vaultauth-kvcluster-app01 -n  kvcluster-app01-ns --context kv-cluster
```
kubectl --context kv-cluster apply -f - <<EOF
---
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultStaticSecret
metadata:
  name: kvcluster-app01-secret
  namespace: kvcluster-app01-ns
spec:
  vaultAuthRef: vaultauth-kvcluster-app01
  mount: kvcluster-kvv2
  type: kv-v2
  path:  app01/creds
  version: 1 # secrets version
  refreshAfter: 30s
  destination:
    create: true
    name: kvcluster-app01-secret
  rolloutRestartTargets:
  - kind: Deployment
    name: kvcluster-app01
---
EOF
```
```
$ kubectl get secret -n kvcluster-app01-ns --context kv-cluster


watch 'kubectl get secrets kvcluster-app01-secret -n kvcluster-app01-ns --context kv-cluster -o json | jq ".data | map_values(@base64d)"'

vault kv put kvcluster-kvv2/app01/creds username='app01v2' password='supersecretpasswordv2'

vault kv put kvcluster-kvv2/app01/creds username='app01v3' password='supersecretpasswordv3'



```
============================================

# Application can now uses Kubernetes Secrets by injecting it through
* volume mount (or)
* environment variable

tee kvcluster-app01-deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kvcluster-app01
  namespace: kvcluster-app01-ns
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kvcluster-app01
  template:
    metadata:
      labels:
        app: kvcluster-app01
    spec:
      containers:
      - name: test
        image: jfrappier/dynamic-exampleapp:latest
        ports:
        - containerPort: 5000
        env:
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: kvcluster-app01-secret
              key: username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: kvcluster-app01-secret
              key: password
EOF

# apply
kubectl apply -f kvcluster-app01-deployment.yaml -n kvcluster-app01-ns --context kv-cluster


# access the app `secret endpoint` to display the k8s secret `created by VSO`
watch "kubectl --context kv-cluster exec --namespace kvcluster-app01-ns --stdin=true  $(kubectl --context kv-cluster get pods --namespace kvcluster-app01-ns -l app=kvcluster-app01 -o name) -- curl http://127.0.0.1:5000/secret --silent"



watch kubectl get pods -n kvcluster-app01-ns --context kv-cluster 

vault kv put kvcluster-kvv2/app01/creds username='app01v4' password='supersecretpasswordv4'


vault kv put kvcluster-kvv2/app01/creds username='app01v5' password='supersecretpasswordv5'


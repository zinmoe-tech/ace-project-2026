# before `VSO` can sync secrets from `Vault to Kubernetes`, it needs `a VAULT ROLE to authenticate with`.
# The policy attached the role permits access to the KV secrets engine created in the previous section.

# Create a k8s namespace and serviceaccount to deploy the app
kubectl create ns kvcluster-app03-ns --context kv-cluster
kubectl create sa kvcluster-app03-sa -n kvcluster-app03-ns --context kv-cluster

kubectl --context kv-cluster apply -f - <<EOF
---
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultAuth
metadata:
  name: vaultauth-kvcluster-app03
  namespace: kvcluster-app03-ns
spec:
  vaultConnectionRef: kvcluster-vaultconn/kvcluster-vault-connection
  method: kubernetes
  mount: kvcluster-k8s-auth
  allowedNamespaces:
    - kvcluster-app03-ns
  kubernetes:
    role: kvcluster-kvv2-app03-vault-role #vaultrole
    serviceAccount: kvcluster-app03-sa
    audiences:
      - app03
---
EOF

# verify
kubectl describe vaultauth vaultauth-kvcluster-app03 -n  kvcluster-app03-ns --context kv-cluster
```
kubectl --context kv-cluster apply -f - <<EOF
---
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultStaticSecret
metadata:
  name: kvcluster-app03-secret
  namespace: kvcluster-app03-ns
spec:
  vaultAuthRef: vaultauth-kvcluster-app03
  mount: kvcluster-kvv2
  type: kv-v2
  path:  app03/creds
  # version: 2 # secrets version
  refreshAfter: 30s
  destination:
    create: true
    name: kvcluster-app03-secret
  rolloutRestartTargets:
  - kind: Deployment
    name: kvcluster-app03
---
EOF
```
```
$ k get secrets -n kvcluster-app03-ns --context kv-cluster


watch 'kubectl get secrets kvcluster-app03-secret -n kvcluster-app03-ns --context kv-cluster -o json | jq ".data | map_values(@base64d)"'

vault kv put kvcluster-kvv2/app03/creds username='app03v2' password='supersecretpasswordv2'

vault kv put kvcluster-kvv2/app03/creds username='app03v3' password='supersecretpasswordv3'



```
============================================

# Application can now uses Kubernetes Secrets by injecting it through
* volume mount (or)
* environment variable

tee kvcluster-app03-deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kvcluster-app03
  namespace: kvcluster-app03-ns
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kvcluster-app03
  template:
    metadata:
      labels:
        app: kvcluster-app03
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
              name: kvcluster-app03-secret
              key: username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: kvcluster-app03-secret
              key: password
EOF

# apply
kubectl apply -f kvcluster-app03-deployment.yaml -n kvcluster-app03-ns --context kv-cluster


# access the app `secret endpoint` to display the k8s secret `created by VSO`
watch "kubectl --context kv-cluster exec --namespace kvcluster-app03-ns --stdin=true  $(kubectl --context kv-cluster get pods --namespace kvcluster-app03-ns -l app=kvcluster-app03 -o name) -- curl http://127.0.0.1:5000/secret --silent"



watch kubectl get pods -n kvcluster-app03-ns --context kv-cluster 

vault kv put kvcluster-kvv2/app03/creds username='app03v4' password='supersecretpasswordv4'


vault kv put kvcluster-kvv2/app03/creds username='app03v5' password='supersecretpasswordv5'


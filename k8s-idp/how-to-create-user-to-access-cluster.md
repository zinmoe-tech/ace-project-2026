Full steps — create a user alice in group team-a-developers

# 1. Private key + CSR — CN=user, O=group
openssl genrsa -out alice.key 2048
openssl req -new -key alice.key -out alice.csr \
  -subj "/CN=alice/O=team-a-developers"

# 2. Submit it to the cluster's CSR API
cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: alice
spec:
  request: $(base64 -w0 alice.csr)
  signerName: kubernetes.io/kube-apiserver-client
  usages: ["client auth"]
EOF

# 3. Approve + retrieve the signed cert
kubectl certificate approve alice
kubectl get csr alice -o jsonpath='{.status.certificate}' | base64 -d > alice.crt

# 4. Add a kubeconfig user + context for alice
kubectl config set-credentials alice \
  --client-key=alice.key --client-certificate=alice.crt --embed-certs=true
kubectl config set-context alice --cluster=kind-idp-cluster --user=alice
Now alice authenticates as user alice in group team-a-developers, and your team-a-rbac.yaml RoleBinding (kind: Group, name: team-a-developers) applies to her. Test it:


kubectl --context alice get pods -n team-a        # allowed if RBAC grants it
kubectl --context alice get pods -n team-b        # should be forbidden
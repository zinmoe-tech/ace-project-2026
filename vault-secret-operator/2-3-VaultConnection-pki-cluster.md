# create namespaces for VaultConnection CRD
kubectl create ns pkicluster-vaultconn --context pki-cluster

export VAULT_ADDR=http://localhost:8200 ### vault connection won't work
export VAULT_ADDR=http://172.18.0.2:8200 ### vaultconnection will work 

kubectl --context pki-cluster apply -f - <<EOF
---
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultConnection
metadata:
  # namespace
  namespace: pkicluster-vaultconn
  name: pkicluster-vault-connection
spec:
  # address to the Vault server.
  address: $VAULT_ADDR
  skipTLSVerify: true
---
EOF

# verify
# kubectl describe vaultconnection -n pkicluster-vaultconn --context pki-cluster

Name:         pkicluster-vault-connection
Namespace:    pkicluster-vaultconn
Labels:       <none>
Annotations:  <none>
API Version:  secrets.hashicorp.com/v1beta1
Kind:         VaultConnection
Metadata:
  Creation Timestamp:  2026-03-18T11:55:53Z
  Finalizers:
    vaultconnection.secrets.hashicorp.com/finalizer
  Generation:        1
  Resource Version:  2006
  UID:               9a898a92-be9b-487f-bf7b-f1ad0b010f3c
Spec:
  Address:          http://172.18.0.2:8200
  Skip TLS Verify:  true
Status:
  Conditions:
    Last Transition Time:  2026-03-18T11:55:53Z
    Message:               Vault ping, address=http://172.18.0.2:8200
    Observed Generation:   1
    Reason:                Accepted
    Status:                True
    Type:                  VaultPing
    Last Transition Time:  2026-03-18T11:55:53Z
    Message:               Successfully validated resource, address=http://172.18.0.2:8200
    Observed Generation:   1
    Reason:                Accepted
    Status:                True
    Type:                  ResourceValidation
    Last Transition Time:  2026-03-18T11:55:53Z
    Message:               VaultConnectionHealthy
    Observed Generation:   1
    Reason:                Healthy
    Status:                True
    Type:                  Healthy
    Last Transition Time:  2026-03-18T11:55:53Z
    Message:               VaultConnectionReady
    Observed Generation:   1
    Reason:                Ready
    Status:                True
    Type:                  Ready
  Valid:                   true
Events:
  Type    Reason    Age   From             Message
  ----    ------    ----  ----             -------
  Normal  Accepted  4s    VaultConnection  VaultConnection accepted
# create namespaces for VaultConnection CRD
kubectl create ns dbcluster-vaultconn --context db-cluster

export VAULT_ADDR=http://localhost:8200 ### vault connection won't work
export VAULT_ADDR=http://172.18.0.10:8200 ### vaultconnection will work 

kubectl --context db-cluster apply -f - <<EOF
---
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultConnection
metadata:
  # namespace
  namespace: dbcluster-vaultconn
  name: dbcluster-vault-connection
spec:
  # address to the Vault server.
  address: $VAULT_ADDR
  skipTLSVerify: true
---
EOF

# verify
# kubectl describe vaultconnection -n dbcluster-vaultconn --context db-cluster

Name:         dbcluster-vault-connection
Namespace:    dbcluster-vaultconn
Labels:       <none>
Annotations:  <none>
API Version:  secrets.hashicorp.com/v1beta1
Kind:         VaultConnection
Metadata:
  Creation Timestamp:  2026-03-18T11:54:56Z
  Finalizers:
    vaultconnection.secrets.hashicorp.com/finalizer
  Generation:        1
  Resource Version:  2052
  UID:               092af91b-5ba2-49a7-bd12-b02631b70372
Spec:
  Address:          http://172.18.0.2:8200
  Skip TLS Verify:  true
Status:
  Conditions:
    Last Transition Time:  2026-03-18T11:54:56Z
    Message:               Vault ping, address=http://172.18.0.2:8200
    Observed Generation:   1
    Reason:                Accepted
    Status:                True
    Type:                  VaultPing
    Last Transition Time:  2026-03-18T11:54:56Z
    Message:               Successfully validated resource, address=http://172.18.0.2:8200
    Observed Generation:   1
    Reason:                Accepted
    Status:                True
    Type:                  ResourceValidation
    Last Transition Time:  2026-03-18T11:54:56Z
    Message:               VaultConnectionHealthy
    Observed Generation:   1
    Reason:                Healthy
    Status:                True
    Type:                  Healthy
    Last Transition Time:  2026-03-18T11:54:56Z
    Message:               VaultConnectionReady
    Observed Generation:   1
    Reason:                Ready
    Status:                True
    Type:                  Ready
  Valid:                   true
Events:
  Type    Reason    Age   From             Message
  ----    ------    ----  ----             -------
  Normal  Accepted  5s    VaultConnection  VaultConnection accepted
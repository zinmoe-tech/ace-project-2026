# Sync Dynamic Secrets
* When a credential TTL is reached, Vault revokes the credentials.
* Vault's DB Secrets Engine creates
    * Dynamic
    * Just-in-time credentials
    * short lived
    * limiting the potential exposure of the credentials

# Run PostgreSQL-prod container
docker run -d --name postgres-prod \
  --sysctl net.ipv6.conf.all.disable_ipv6=1 \
  -e POSTGRES_USER=root-prod \
  -e POSTGRES_PASSWORD=rootpassword-prod \
  --publish 127.0.0.1:5432:5432 \
  --network kind \
  --rm postgres


# TablePlus App to connect to `postgres-prod` databases
172.18.0.8:5432 (or) 127.0.0.1:5432 # PROD
username: root-prod
password: rootpassword-prod




# Enable database secrets engine
export VAULT_ADDR=http://172.18.0.10:8200
export VAULT_TOKEN=root

# Enable database secrets enigne in the path `dbcluster-postgres-prod`
vault secrets enable -path=dbcluster-postgres-prod database

# Configure the database secrets engine to use the `postgresql-database-plugin` and the PostgreSQL `root` credentials

vault write dbcluster-postgres-prod/config/postgresql \
  plugin_name=postgresql-database-plugin \
  connection_url="postgresql://{{username}}:{{password}}@172.18.0.4:5432/postgres?sslmode=disable" \
  allowed_roles=dbcluster-postgres-prod-vault-role \
  username="root-prod" \
  password="rootpassword-prod"

* Note: Rotate Root Credentials https://developer.hashicorp.com/vault/api-docs/secret/databases#rotate-root-credentials

vault write -f dbcluster-postgres-prod/rotate-root/postgresql

# Configure a VAULT ROLE `dbcluster-postgres-prod-vault-role` that includes a SQL statement to create the PostgreSQL role.

vault write dbcluster-postgres-prod/roles/dbcluster-postgres-prod-vault-role \
     db_name="postgresql" \
     creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
         GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
     default_ttl="3m" \
     max_ttl="3m"

# test the Vault Role to generate PostgreSQL credentials
vault read dbcluster-postgres-prod/creds/dbcluster-postgres-prod-vault-role

Key                Value
---                -----
lease_id           dbcluster-postgres-prod/creds/dbcluster-postgres-prod-vault-role/DULKM3sJkt11ZKq8yQFJOiGX
lease_duration     3m
lease_renewable    true
password           QWrE7adxDu50Z7L-YlfJ
username           v-token-dbcluste-4hl0KXynzeQlb6rfIArY-1773826264

#### Use Table Plus to connect to test, it should fail after 3 minutes ####

# create policy that allows access to the database secrets engine.

vault policy write dbcluster-postgres-prod-policy - <<EOF
path "dbcluster-postgres-prod/creds/dbcluster-postgres-prod-vault-role" {
  capabilities = [ "read" ]
}
EOF

# create a vault role for the app with the `dbcluster-postgres-prod-vault-role` policy attached.
vault write auth/dbcluster-k8s-auth/role/dbcluster-postgres-prod-vault-role \
bound_service_account_names=dbcluster-postgres-prod-sa \
bound_service_account_namespaces=dbcluster-postgres-prod-ns \
policies=dbcluster-postgres-prod-policy \
audience=dynamicapp01 \
ttl=1h

==================================================

kubectl create ns dbcluster-postgres-prod-ns --context db-cluster
kubectl create sa dbcluster-postgres-prod-sa -n dbcluster-postgres-prod-ns --context db-cluster

# VaultAuth CRD

kubectl --context db-cluster apply -f - <<EOF
---
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultAuth
metadata:
  name: vaultauth-dbcluster-postgres-prod
  namespace: dbcluster-postgres-prod-ns
spec:
  vaultConnectionRef: dbcluster-vaultconn/dbcluster-vault-connection
  method: kubernetes
  mount: dbcluster-k8s-auth
  allowedNamespaces:
    - dbcluster-postgres-prod-ns
  kubernetes:
    role: dbcluster-postgres-prod-vault-role
    serviceAccount: dbcluster-postgres-prod-sa
    audiences:
      - dynamicapp01
---
EOF


# verify VaultAuth
kubectl describe vaultauth vaultauth-dbcluster-postgres-prod -n  dbcluster-postgres-prod-ns --context db-cluster


# VaultDynamicSecret CRD
kubectl --context db-cluster apply -f - <<EOF
---
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultDynamicSecret
metadata:
  name: dbcluster-postgres-prod-secret
  namespace: dbcluster-postgres-prod-ns
spec:
  vaultAuthRef: vaultauth-dbcluster-postgres-prod
  mount: dbcluster-postgres-prod
  path:  creds/dbcluster-postgres-prod-vault-role
  refreshAfter: 30s
  destination:
    create: true
    name: dbcluster-postgres-prod-secret
  rolloutRestartTargets:
  - kind: Deployment
    name: dbcluster-postgres-prod
---
EOF


# kubectl get secrets -n dbcluster-postgres-prod-ns --context db-cluster

kubectl get secrets -n dbcluster-postgres-prod-ns --context db-cluster -o yaml

echo "di1kYmNsdXN0ZS1kYmNsdXN0ZS1TY1NMTVZ3THNieFZHSml6VkEyNy0xNzczODI4Mjc4" | base64 -d
v-dbcluste-dbcluste-ScSLMVwLsbxVGJizVA27-1773828278

echo "OVpBMGVPNW5hekY1RnVPN3g2LW4=" | base64 -d
9ZA0eO5nazF5FuO7x6-n


# Read K8s secret and decode the base64 encoded string
watch 'kubectl --context db-cluster get secrets dbcluster-postgres-prod-secret -n dbcluster-postgres-prod-ns -o json | jq ".data | map_values(@base64d)"'

# you can test using below credentials
  "password": "B18J-zUZ6DmsxvRyeaEw",
  "username": "v-dbcluste-dbcluste-voirsWzsv9V46ZPvYyeO-1773828534"


# Application can now uses Kubernetes Secrets by injecting it through
* volume mount (or)
* environment variable

tee dbcluster-postgres-prod-deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dbcluster-postgres-prod
  namespace: dbcluster-postgres-prod-ns
spec:
  replicas: 1
  selector:
    matchLabels:
      app: dbcluster-postgres-prod
  template:
    metadata:
      labels:
        app: dbcluster-postgres-prod
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
              name: dbcluster-postgres-prod-secret
              key: username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: dbcluster-postgres-prod-secret
              key: password
        - name: DB_HOST
          value: "172.18.0.8"
        - name: DB_PORT
          value: "5432"
        - name: DB_NAME
          value: "postgres"
EOF

# apply
kubectl apply -f dbcluster-postgres-prod-deployment.yaml -n dbcluster-postgres-prod-ns --context db-cluster


# access the app `secret endpoint` to display the k8s secret `created by VSO`

watch 'kubectl --context db-cluster exec --namespace dbcluster-postgres-prod-ns --stdin=true \
    $(kubectl --context db-cluster get pods --namespace dbcluster-postgres-prod-ns -l app=dbcluster-postgres-prod -o name) \
    -- curl http://127.0.0.1:5000/secret --silent'

watch kubectl get pods -n dbcluster-postgres-prod-ns --context db-cluster





# troubleshoot option 1
kubectl --context db-cluster exec -it -n dbcluster-postgres-prod-ns $(kubectl --context db-cluster get pods -n dbcluster-postgres-prod-ns -l app=dbcluster-postgres-prod -o name) -- bash -c "timeout 5 bash -c '</dev/tcp/172.18.0.9/5432' && echo 'Connection successful' || echo 'Connection failed'"

`output from above should show Connection successful`

# troubleshoot option 2
# troubleshoot option 2
kubectl --context db-cluster exec -it -n dbcluster-postgres-prod-ns $(kubectl --context db-cluster get pods -n dbcluster-postgres-prod-ns -l app=dbcluster-postgres-prod -o name) -- nc -zv 172.18.0.9 5432
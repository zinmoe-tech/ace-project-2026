# Keycloak — JWT Client Authentication for HelloCloudBank

## What is Keycloak?
Keycloak is an open-source **Identity Provider (IdP)**.
Instead of your services managing passwords, Keycloak handles login and issues a **JWT token**.
Every request then carries that token and your services only need to verify it.

---

## How it fits into this project

```
 ┌──────────┐  (1) POST /token   ┌───────────┐
 │  Client  │ ─────────────────► │ Keycloak  │
 │  (curl)  │ ◄───────────────── │ :8080     │
 └──────────┘  (2) JWT token     └───────────┘
      │
      │ (3) GET /retail-banking/...
      │     Authorization: Bearer <JWT>
      ▼
 ┌──────────┐
 │   Kong   │  API Gateway (172.18.255.190)
 └────┬─────┘
      │ routes to Istio IngressGateway
      ▼
 ┌─────────────────────────────┐
 │   Istio Sidecar (Envoy)     │
 │                             │
 │  Layer 1 — SPIFFE / mTLS    │  Is the caller a known service? (identity)
 │  Layer 2 — JWT Validation   │  Is the token signed by Keycloak? (authn)
 │  Layer 3 — Role Check       │  Does the token have the right role? (authz)
 └────────────┬────────────────┘
              │ all 3 pass ✅
              ▼
      ┌───────────────┐
      │ Your Services │  customer-profile-svc → account-svc → statement-svc
      └───────────────┘
```

---

## Files in this folder

| File | Purpose |
|------|---------|
| `00-namespace.yaml` | Creates the `keycloak` namespace (no Istio sidecar — Keycloak is outside the mesh) |
| `01-keycloak.yaml` | Deploys Keycloak 26.0.0 in dev mode with a MetalLB LoadBalancer service |
| `02-request-authentication.yaml` | Tells Istio **how** to validate JWT tokens (JWKS URI, issuer) |
| `10-authz-policy-retail-group.yaml` | Tells Istio **who** is allowed in (group check + deny-no-token) |

---

## DNS & IP Reference

| Hostname | IP | Port | What it is |
|----------|----|------|------------|
| `finance.hellocloud.io` | `172.18.255.190` | 80 | Kong → Istio gateway |
| `keycloak.hellocloud.io` | `172.18.255.194` | 8080 | Keycloak LoadBalancer |

Both entries must exist in `/etc/hosts` on your machine:
```
172.18.255.190  finance.hellocloud.io
172.18.255.194  keycloak.hellocloud.io
```

---

## Role → Namespace Access Map

| Keycloak Role | Can access namespace |
|---------------|---------------------|
| `retail-banking-user` | `retail-banking-team` |
| `payments-user` | `payments-team` |
| `grc-user` | `grc-team` |

---

## Step-by-Step Setup

### Step 1 — Deploy Keycloak

```bash
kubectl apply -f keycloak/00-namespace.yaml
kubectl apply -f keycloak/01-keycloak.yaml
```

Wait until the pod is **Running**:
```bash
kubectl get pods -n keycloak -w
# NAME                        READY   STATUS    RESTARTS
# keycloak-xxxx               1/1     Running   0        ← wait for this
```

> ⏱ Takes ~30 seconds due to the `readinessProbe`.

---

### Step 2 — Add Keycloak to /etc/hosts

```bash
# Check what IP MetalLB assigned
kubectl get svc keycloak -n keycloak
# NAME       TYPE           CLUSTER-IP    EXTERNAL-IP      PORT(S)
# keycloak   LoadBalancer   10.96.x.x     172.18.255.194   8080:xxxxx/TCP

sudo sh -c 'echo "172.18.255.194  keycloak.hellocloud.io" >> /etc/hosts'
```

Verify it resolves:
```bash
curl -s http://keycloak.hellocloud.io:8080/realms/master | python3 -m json.tool
# {
#     "realm": "master",   ← Keycloak is reachable ✅
```

---

### Step 3 — Create the Realm

1. Open browser: **http://keycloak.hellocloud.io:8080**
2. Login: `admin` / `admin`
3. Top-left dropdown → **Create Realm**
4. Realm name: `hellocloudbank`
5. Click **Create**

> ⚠️ **Dev mode warning:** Keycloak uses an embedded H2 database. All data (realm, users, roles) is **lost when the pod restarts**. See the [Recreate section](#recreate-keycloak-data-after-pod-restart) below if that happens.

---

### Step 4 — Create a Client

1. Left menu → **Clients** → **Create client**
2. Set these values:

   | Field | Value |
   |-------|-------|
   | Client type | `OpenID Connect` |
   | Client ID | `retail-banking-client` |

3. Click **Next**
4. Turn **Client authentication: ON**

   > This makes it a **confidential client** — it requires a `client_secret` when requesting tokens. Without this, your `curl` will get `unauthorized_client`.

5. Click **Next** → **Save**
6. Go to **Credentials** tab → copy the **Client Secret**

   ```
   Example: 3mvHOLWKWNjH4Jl19Z8Ew7qAm3j4ysfk
   ```

---

### Step 5 — Create Realm Roles

1. Left menu → **Realm roles** → **Create role**
2. Create these three roles one by one:

   | Role name |
   |-----------|
   | `retail-banking-user` |
   | `payments-user` |
   | `grc-user` |

---

### Step 6 — Create a Test User

1. Left menu → **Users** → **Create user**
2. Fill in **ALL** of the following fields (Keycloak 26 requires them all):

   | Field | Value |
   |-------|-------|
   | Username | `alice` |
   | First name | `Alice` |
   | Last name | `Smith` |
   | Email | `alice@hellocloudbank.com` |
   | Email verified | **ON** ← toggle this |

3. Click **Create**

4. Go to **Credentials** tab → **Set password**:
   - Password: `alice123`
   - **Temporary: OFF** ← critical! If left ON, login fails with `Account is not fully set up`

5. Go to **Role mapping** tab → **Assign role** → select `retail-banking-user`

> ⚠️ **Common mistakes that cause `Account is not fully set up`:**
> - Missing First name, Last name, Email, or Email verified
> - Password left as Temporary (must be OFF)

---

### Step 7 — Apply Istio JWT Policies

```bash
kubectl apply -f keycloak/02-request-authentication.yaml
kubectl apply -f keycloak/10-authz-policy-retail-group.yaml
```

Verify they were created:
```bash
kubectl get requestauthentication -A
# NAMESPACE             NAME          AGE
# retail-banking-team   keycloak-jwt   ...
# payments-team         keycloak-jwt   ...
# grc-team              keycloak-jwt   ...

kubectl get authorizationpolicy -n retail-banking-team
# NAME                        ACTION   AGE
# deny-no-jwt-retail-banking  DENY     ...
# require-jwt-customer-profile-svc  ALLOW    ...
```

---

### Step 8 — Get a JWT Token

```bash
RETAIL_TOKEN=$(curl -s -X POST \
  http://keycloak.hellocloud.io:8080/realms/hellocloudbank/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=retail-banking-client" \
  -d "client_secret=xG128zVQdKDbLVPXgeYk1Jy36AgljfoE" \
  -d "username=alice" \
  -d "password=alice123" \
  -d "grant_type=password" | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

echo $RETAIL_TOKEN
# eyJhbGciOiJSUzI1NiIsInR5cCIgOi...   ← long JWT string means success
```

> Replace `<YOUR_CLIENT_SECRET>` with the value from **Step 4**.

Inspect what's inside the token:
```bash
echo $TOKEN | cut -d'.' -f2 | python3 -c "
import sys, base64, json
payload = sys.stdin.read().strip()
payload += '=' * (4 - len(payload) % 4)
data = json.loads(base64.urlsafe_b64decode(payload))
print('iss   :', data.get('iss'))
print('sub   :', data.get('sub'))
print('email :', data.get('email'))
print('roles :', data.get('realm_access', {}).get('roles'))
"
# iss   : http://keycloak.hellocloud.io:8080/realms/hellocloudbank
# sub   : <uuid>
# email : alice@hellocloudbank.com
# roles : ['retail-banking-user', 'default-roles-hellocloudbank', 'offline_access', 'uma_authorization']
```

---

### Step 9 — Test All Three Cases

```bash
# ✅ Case 1: Valid token + correct role → should return 200
curl -s -o /dev/null -w "HTTP: %{http_code}\n" \
  -H "Host: finance.hellocloud.io" \
  -H "Authorization: Bearer $TOKEN" \
  http://172.18.255.190/retail-banking/customer-profile-svc

# ❌ Case 2: Valid token but WRONG role (alice has retail-banking-user, not payments-user) → should return 401
curl -s -o /dev/null -w "HTTP: %{http_code}\n" \
  -H "Host: finance.hellocloud.io" \
  -H "Authorization: Bearer $TOKEN" \
  http://172.18.255.190/payments/transactions

# ❌ Case 3: No token at all → should return 403
curl -s -o /dev/null -w "HTTP: %{http_code}\n" \
  -H "Host: finance.hellocloud.io" \
  http://172.18.255.190/retail-banking/customer-profile-svc
```

Expected output:
```
HTTP: 200   ← alice can access her own namespace ✅
HTTP: 401   ← alice cannot access payments (wrong role) ✅
HTTP: 403   ← no token blocked at the door ✅
```

---

## How the JWT Security Layers Work

### Layer 1 — `02-request-authentication.yaml` (Token Validation)

Istio's sidecar downloads Keycloak's public keys from the `jwksUri` and uses them to **verify the token signature** on every request.

- Invalid token (tampered/expired) → **401 Unauthorized**
- No token → passed through to the next layer (not rejected here)

```
issuer:  http://keycloak.hellocloud.io:8080/realms/hellocloudbank
           ↑ must match the "iss" claim inside the token

jwksUri: http://keycloak.keycloak.svc.cluster.local:8080/...
           ↑ cluster-internal DNS — Istio sidecar fetches keys from inside the cluster
             (not external, so it works even without a Keycloak ingress)
```

> **Why two different URLs?**
> - `issuer` = what's stamped inside the token (uses the external hostname clients see)
> - `jwksUri` = where Istio fetches public keys (uses internal DNS — faster, no egress)

### Layer 2 — `10-authz-policy-retail-group.yaml` (Group Enforcement)

Two policies work together:

| Policy | Action | Purpose |
|--------|--------|---------|
| `deny-no-jwt-retail-banking` | DENY | Blocks requests with **no JWT** at `customer-profile-svc` |
| `require-jwt-customer-profile-svc` | ALLOW | Allows requests with valid token AND correct group |

**Why is the DENY policy needed?**
SPIFFE/mTLS policies (in `authz-retail-banking.yaml`) allow IngressGateway → `customer-profile-svc` based on pod identity — they don't check JWTs.
Without the DENY policy, requests with **no token** would slip through via SPIFFE trust.

**Why is DENY only on `customer-profile-svc`?**
It's the first service hit from the gateway (the mesh entry point).
Internal calls (account-svc → statement-svc) use SPIFFE identity, not JWT — so they must not be blocked.

```
External request (no JWT)
    ↓
Kong → IngressGateway → customer-profile-svc
                              ↑
                         DENY blocks here (no JWT principal) ✅

Internal call (SPIFFE only)
    account-svc → statement-svc
         ↑
    No JWT needed — SPIFFE handles this ✅
```

---

## Recreate Keycloak Data After Pod Restart

Dev mode loses all data on restart. Run this to recreate everything via the Admin API:

```bash
# 1. Get admin token
ADMIN_TOKEN=$(curl -s -X POST \
  http://keycloak.hellocloud.io:8080/realms/master/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=admin-cli" \
  -d "username=admin" \
  -d "password=admin" \
  -d "grant_type=password" | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

# 2. Create realm
curl -s -X POST http://keycloak.hellocloud.io:8080/admin/realms \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"realm":"hellocloudbank","enabled":true}'

# 3. Create client (confidential, with fixed secret)
curl -s -X POST http://keycloak.hellocloud.io:8080/admin/realms/hellocloudbank/clients \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "retail-banking-client",
    "enabled": true,
    "publicClient": false,
    "clientAuthenticatorType": "client-secret",
    "secret": "3mvHOLWKWNjH4Jl19Z8Ew7qAm3j4ysfk",
    "directAccessGrantsEnabled": true
  }'

# 4. Create roles
for ROLE in retail-banking-user payments-user grc-user; do
  curl -s -X POST http://keycloak.hellocloud.io:8080/admin/realms/hellocloudbank/roles \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"$ROLE\"}"
done

# 5. Create alice user
curl -s -X POST http://keycloak.hellocloud.io:8080/admin/realms/hellocloudbank/users \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "alice",
    "firstName": "Alice",
    "lastName": "Smith",
    "email": "alice@hellocloudbank.com",
    "emailVerified": true,
    "enabled": true,
    "credentials": [{"type":"password","value":"alice123","temporary":false}]
  }'

# 6. Assign retail-banking-user role to alice
ALICE_ID=$(curl -s "http://keycloak.hellocloud.io:8080/admin/realms/hellocloudbank/users?username=alice" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['id'])")

ROLE_ID=$(curl -s "http://keycloak.hellocloud.io:8080/admin/realms/hellocloudbank/roles/retail-banking-user" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['id'])")

curl -s -X POST "http://keycloak.hellocloud.io:8080/admin/realms/hellocloudbank/users/$ALICE_ID/role-mappings/realm" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "[{\"id\":\"$ROLE_ID\",\"name\":\"retail-banking-user\"}]"

echo "Done. Test with:"
echo "curl -s -X POST http://keycloak.hellocloud.io:8080/realms/hellocloudbank/protocol/openid-connect/token \\"
echo "  -d 'client_id=retail-banking-client&client_secret=3mvHOLWKWNjH4Jl19Z8Ew7qAm3j4ysfk&username=alice&password=alice123&grant_type=password'"
```

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `Could not resolve host: keycloak.hellocloud.io` | Missing /etc/hosts entry | `sudo sh -c 'echo "172.18.255.194  keycloak.hellocloud.io" >> /etc/hosts'` |
| `Realm does not exist` | Pod restarted, dev-mode data lost | Re-run the [recreate script](#recreate-keycloak-data-after-pod-restart) |
| `unauthorized_client` | Missing `client_secret` in curl | Add `-d "client_secret=<secret>"` |
| `invalid_grant` / wrong password | Wrong credentials | Verify user password in Keycloak UI |
| `Account is not fully set up` | Temporary password ON, or missing name/email fields | Re-create user with all fields filled and Temporary: OFF |
| HTTP 401 (token rejected) | `iss` in token doesn't match `issuer` in RequestAuthentication | Decode token with `echo $TOKEN \| cut -d'.' -f2 \| base64 -d` and compare iss value |
| HTTP 401 (wrong role) | User doesn't have the required role | Assign the correct role in Keycloak UI → Role mapping |
| HTTP 403 (no token) | DENY policy is working correctly | Add a valid token to your request |
| HTTP 200 without token | `deny-no-jwt` policy not applied | `kubectl apply -f keycloak/10-authz-policy-retail-group.yaml` |

---

## Key Concepts

| Term | Meaning |
|------|---------|
| **Realm** | A tenant/space in Keycloak — all your users, clients, and roles live here |
| **Client** | Your app that requests tokens (`retail-banking-client`) |
| **Client Authentication ON** | Confidential client — requires `client_secret` in token requests |
| **Role** | Permission label in the JWT (`retail-banking-user`, `payments-user`, `grc-user`) |
| **JWT** | JSON Web Token — a signed, self-contained proof of who the user is and what roles they have |
| **iss (issuer)** | URL stamped in the token identifying who created it — must match `RequestAuthentication.issuer` |
| **JWKS URI** | URL where Istio downloads Keycloak's public keys to verify token signatures |
| **RequestAuthentication** | Istio resource — tells Istio HOW to validate the JWT (which issuer, where to get keys) |
| **AuthorizationPolicy ALLOW** | Istio resource — who IS allowed in (valid JWT + correct role) |
| **AuthorizationPolicy DENY** | Istio resource — who is explicitly blocked (no JWT at all) |
| **SPIFFE** | Pod-level mTLS identity — separate from JWT, used for service-to-service calls inside the mesh |


curl -s -o /dev/null -w "HTTP: %{http_code}\n" \
  -H "Host: finance.hellocloud.io" \
  -H "Authorization: Bearer $RETAIL_TOKEN" \
  http://172.18.255.190/retail-banking/customer-profile-svc

  # Check if token is valid / how long left
bash keycloak/get-token.sh status

# Force get a new token right now
bash keycloak/get-token.sh refresh

# Fetch once, export $TOKEN into current shell
source keycloak/get-token.sh

# Auto-refresh in background every 55 min (set & forget)
bash keycloak/get-token.sh &


<!-- # Get admin token
ADMIN_TOKEN=$(curl -s -X POST \
  http://keycloak.hellocloud.io:8080/realms/master/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=admin-cli&username=admin&password=admin&grant_type=password" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

# Get alice's ID
ALICE_ID=$(curl -s "http://keycloak.hellocloud.io:8080/admin/realms/hellocloudbank/users?username=alice" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['id'])")

echo "Alice ID: $ALICE_ID"

# Reset password with temporary=false
curl -s -X PUT \
  "http://keycloak.hellocloud.io:8080/admin/realms/hellocloudbank/users/$ALICE_ID/reset-password" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"type":"password","value":"alice123","temporary":false}'

echo "Password reset done" -->

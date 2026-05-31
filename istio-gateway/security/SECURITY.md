# Security Documentation — HelloCloudBank

> **Stack:** Istio 1.29.2 · Keycloak 26.0.0 · Kong OSS 3.9.1  
> **Cluster:** Kind v1.34 · 4 nodes · MetalLB · SPIFFE/mTLS mesh-wide

---

## 1. Security Controls Overview

| # | Control | Kind | Scope | File |
|---|---------|------|-------|------|
| 1 | **Mesh-wide mTLS STRICT** | `PeerAuthentication` | All namespaces (istio-system) | `peer-authentication.yaml` |
| 2 | **JWT Signature Validation** | `RequestAuthentication` | retail-banking-team, payments-team, grc-team | `keycloak/02-request-authentication.yaml` |
| 3 | **Deny — No Token** | `AuthorizationPolicy` DENY | retail-banking-team | `keycloak/03-authz-policy-jwt.yaml` |
| 4 | **Deny — Wrong Namespace Token** | `AuthorizationPolicy` DENY | retail-banking-team, payments-team, grc-team | `keycloak/03-authz-policy-jwt.yaml` |
| 5 | **Allow — Valid JWT** | `AuthorizationPolicy` ALLOW | retail-banking-team, payments-team, grc-team | `keycloak/03-authz-policy-jwt.yaml` |
| 6 | **Deny-All Default** | `AuthorizationPolicy` DENY | All 6 team + ingress namespaces | `authz-*.yaml` |
| 7 | **Allow IngressGateway → Services** | `AuthorizationPolicy` ALLOW | retail-banking-team, payments-team, grc-team | `authz-retail-banking.yaml`, `authz-payments.yaml`, `authz-grc.yaml` |
| 8 | **Allow Kong → IngressGateway** | `AuthorizationPolicy` ALLOW | retail-banking-ingress, payments-ingress, grc-ingress | `authz-*-ingress.yaml` |
| 9 | **Allow Service-to-Service** | `AuthorizationPolicy` ALLOW | retail-banking-team | `authz-retail-banking.yaml` |
| 10 | **ClusterIP — No External Exposure** | `Service` (ClusterIP) | retail-banking-ingress, payments-ingress, grc-ingress | `minimal-profile.yaml` |

---

## 2. mTLS — PeerAuthentication

| Resource | Namespace | Mode | Effect |
|----------|-----------|------|--------|
| `mesh-mtls-strict` | `istio-system` (mesh-wide) | `STRICT` | All pod-to-pod traffic must use mTLS. Plain HTTP between sidecars is rejected. Each pod must present a valid SPIFFE X.509 certificate. |

**SPIFFE Identity Format:**
```
spiffe://cluster.local/ns/<namespace>/sa/<service-account>
```
Istio strips `spiffe://` automatically when matching `principals` in AuthorizationPolicy.

---

## 3. JWT Authentication — RequestAuthentication

Applied to all three team namespaces. Istio sidecars validate every incoming JWT using Keycloak's public keys.

| Field | Value |
|-------|-------|
| **Issuer (`iss` claim)** | `http://keycloak.hellocloud.io:8080/realms/hellocloudbank` |
| **JWKS URI** | `http://keycloak.keycloak.svc.cluster.local:8080/realms/hellocloudbank/protocol/openid-connect/certs` |
| **Token Location** | `Authorization: Bearer <token>` header |
| **Forward Token** | `true` — token is passed to upstream services |
| **Invalid token** | → `401 Unauthorized` (rejected by Istio immediately) |
| **No token** | → passed through to AuthorizationPolicy (handled by DENY rule) |

> **Why two different hostnames?**  
> `iss` uses `keycloak.hellocloud.io` (set by `KC_HOSTNAME` env var in Keycloak — this is what appears in the token).  
> `jwksUri` uses cluster-internal DNS — Istio fetches keys inside the cluster without going through DNS or external network.

---

## 4. AuthorizationPolicy — Ingress Namespaces

Each dedicated ingress namespace has a **deny-all + two explicit ALLOWs** pattern.

### retail-banking-ingress

| Policy Name | Action | Selector | Allowed From | Port |
|-------------|--------|----------|--------------|------|
| `retail-banking-ingress-deny-all` | DENY (default) | — (all pods) | ❌ Everything | all |
| `allow-kong-to-retail-banking-ingressgateway` | ALLOW | `app: retail-banking-istio-ingressgateway` | Any source | `8080` |
| `allow-healthcheck-retail-banking-ingressgateway` | ALLOW | `app: retail-banking-istio-ingressgateway` | Any source | `15021` |

### payments-ingress

| Policy Name | Action | Selector | Allowed From | Port |
|-------------|--------|----------|--------------|------|
| `payments-ingress-deny-all` | DENY (default) | — (all pods) | ❌ Everything | all |
| `allow-kong-to-payments-ingressgateway` | ALLOW | `app: payments-istio-ingressgateway` | Any source | `8080` |
| `allow-healthcheck-payments-ingressgateway` | ALLOW | `app: payments-istio-ingressgateway` | Any source | `15021` |

### grc-ingress

| Policy Name | Action | Selector | Allowed From | Port |
|-------------|--------|----------|--------------|------|
| `grc-ingress-deny-all` | DENY (default) | — (all pods) | ❌ Everything | all |
| `allow-kong-to-grc-ingressgateway` | ALLOW | `app: grc-istio-ingressgateway` | Any source | `8080` |
| `allow-healthcheck-grc-ingressgateway` | ALLOW | `app: grc-istio-ingressgateway` | Any source | `15021` |

---

## 5. AuthorizationPolicy — Team Namespaces (SPIFFE / mTLS)

### retail-banking-team

| Policy Name | Action | Selector (Target) | Allowed From (SPIFFE Principal) | Port |
|-------------|--------|--------------------|----------------------------------|------|
| `retail-banking-deny-all` | DENY (default) | — (all pods) | ❌ Everything | all |
| `allow-ingressgateway-to-account-svc` | ALLOW | `app: account-svc` | `cluster.local/ns/retail-banking-ingress/sa/retail-banking-istio-ingressgateway-service-account` | `9092` |
| `allow-ingressgateway-to-customer-profile-svc` | ALLOW | `app: customer-profile-svc` | `cluster.local/ns/retail-banking-ingress/sa/retail-banking-istio-ingressgateway-service-account` | `9091` |
| `allow-ingressgateway-to-statement-svc` | ALLOW | `app: statement-svc` | `cluster.local/ns/retail-banking-ingress/sa/retail-banking-istio-ingressgateway-service-account` | `9093` |
| `allow-customer-profile-svc-to-account-svc` | ALLOW | `app: account-svc` | `cluster.local/ns/retail-banking-team/sa/customer-profile-svc` | `9092` |
| `allow-account-svc-to-statement-svc` | ALLOW | `app: statement-svc` | `cluster.local/ns/retail-banking-team/sa/account-svc` | `9093` |

### payments-team

| Policy Name | Action | Selector (Target) | Allowed From (SPIFFE Principal) | Port |
|-------------|--------|--------------------|----------------------------------|------|
| `payments-deny-all` | DENY (default) | — (all pods) | ❌ Everything | all |
| `allow-ingressgateway-to-transfer-svc` | ALLOW | `app: transfer-svc` | `cluster.local/ns/payments-ingress/sa/payments-istio-ingressgateway-service-account` | `7071` |
| `allow-ingressgateway-to-payment-gateway-svc` | ALLOW | `app: payment-gateway-svc` | `cluster.local/ns/payments-ingress/sa/payments-istio-ingressgateway-service-account` | `7072` |
| `allow-ingressgateway-to-fx-svc` | ALLOW | `app: fx-svc` | `cluster.local/ns/payments-ingress/sa/payments-istio-ingressgateway-service-account` | `7073` |

### grc-team

| Policy Name | Action | Selector (Target) | Allowed From (SPIFFE Principal) | Port |
|-------------|--------|--------------------|----------------------------------|------|
| `grc-deny-all` | DENY (default) | — (all pods) | ❌ Everything | all |
| `allow-ingressgateway-to-fraud-svc` | ALLOW | `app: fraud-svc` | `cluster.local/ns/grc-ingress/sa/grc-istio-ingressgateway-service-account` | `6061` |
| `allow-ingressgateway-to-audit-svc` | ALLOW | `app: audit-svc` | `cluster.local/ns/grc-ingress/sa/grc-istio-ingressgateway-service-account` | `6062` |
| `allow-ingressgateway-to-sanction-svc` | ALLOW | `app: sanction-svc` | `cluster.local/ns/grc-ingress/sa/grc-istio-ingressgateway-service-account` | `6063` |

---

## 6. AuthorizationPolicy — JWT Group & Role Enforcement

Applied after SPIFFE checks. Controls which users can access which namespace.

### Policy Evaluation Order (Istio rule: DENY beats ALLOW)

```
Request arrives at sidecar
        │
        ▼
[1] Any DENY policy matches? ──► YES → 403 Forbidden  (stop)
        │ NO
        ▼
[2] Any ALLOW policy matches? ─► YES → 200 OK         (stop)
        │ NO
        ▼
[3] No ALLOW matched ──────────► 403 Forbidden
```

### JWT Policies per Namespace

| Policy Name | Namespace | Action | Condition | Result |
|-------------|-----------|--------|-----------|--------|
| `deny-no-jwt-retail-banking` | `retail-banking-team` | DENY | No JWT present (`notRequestPrincipals: ["*"]`) | **403** — no token |
| `deny-wrong-jwt-retail-banking` | `retail-banking-team` | DENY | Has JWT **AND** `groups` ≠ `senior-group` **AND** `roles` ≠ `retail-banking-user` | **403** — wrong namespace |
| `require-jwt-retail-banking` | `retail-banking-team` | ALLOW | `groups` = `senior-group` **OR** `roles` = `retail-banking-user` | **200** — allowed |
| `deny-wrong-jwt-payments` | `payments-team` | DENY | Has JWT **AND** `groups` ≠ `senior-group` **AND** `roles` ≠ `payments-user` | **403** — wrong namespace |
| `require-jwt-payments` | `payments-team` | ALLOW | `groups` = `senior-group` **OR** `roles` = `payments-user` | **200** — allowed |
| `deny-wrong-jwt-grc` | `grc-team` | DENY | Has JWT **AND** `groups` ≠ `senior-group` **AND** `roles` ≠ `grc-user` | **403** — wrong namespace |
| `require-jwt-grc` | `grc-team` | ALLOW | `groups` = `senior-group` **OR** `roles` = `grc-user` | **200** — allowed |

### JWT Claims Used

| Claim Key | Source | Example Value |
|-----------|--------|---------------|
| `request.auth.claims[groups]` | Keycloak group membership mapper | `["senior-group"]` |
| `request.auth.claims[realm_access][roles]` | Keycloak realm roles | `["retail-banking-user"]` |
| `requestPrincipals` | `iss/sub` from JWT | `http://keycloak.../hellocloudbank/*` |

---

## 7. Role-Based Access Control (RBAC)

### Keycloak Users & Roles

| User | Group | Realm Roles | retail-banking | payments | grc |
|------|-------|-------------|----------------|----------|-----|
| `alice` | `senior-group` | `retail-banking-user`, `payments-user`, `grc-user` | ✅ | ✅ | ✅ |
| `alice` | `junior-group` | `retail-banking-user` | ✅ | ❌ | ❌ |
| `charlie` | `junior-group` | `payments-user` | ❌ | ✅ | ❌ |
| `bob` | `junior-group` | `grc-user` | ❌ | ❌ | ✅ |
| *(no token)* | — | — | ❌ 403 | ❌ 403 | ❌ 403 |

### Why `DENY` is Required (not just `ALLOW`)

```
Without DENY policy:
  charlie (payments-user) sends request to retail-banking-team
    → SPIFFE ALLOW matches (IngressGateway → customer-profile-svc) ✅
    → JWT ALLOW does NOT match (no retail-banking-user role) ❌
    → Istio picks the SPIFFE ALLOW → request PASSES  ← SECURITY BUG

With DENY policy:
  charlie (payments-user) sends request to retail-banking-team
    → DENY fires first: has JWT, groups ≠ senior-group, roles ≠ retail-banking-user → 403 ✅
```

---

## 8. Network Exposure

| Service | Namespace | Type | External IP | Accessible From |
|---------|-----------|------|-------------|-----------------|
| `kong-proxy` (global-kic) | `global-kic` | `LoadBalancer` | `172.18.255.190` | Internet / external clients |
| `retail-banking-istio-ingressgateway` | `retail-banking-ingress` | **`ClusterIP`** | none | Kong only (cluster-internal) |
| `payments-istio-ingressgateway` | `payments-ingress` | **`ClusterIP`** | none | Kong only (cluster-internal) |
| `grc-istio-ingressgateway` | `grc-ingress` | **`ClusterIP`** | none | Kong only (cluster-internal) |
| `keycloak` | `keycloak` | `NodePort` / `LoadBalancer` | `172.18.255.194` | Token generation (external) |
| Microservices (`*-svc`) | team namespaces | `ClusterIP` | none | IngressGateway only (SPIFFE) |

---

## 9. Defence-in-Depth Summary

```
Layer 1 — Network
  └─ IngressGateway services are ClusterIP (no external IP)
  └─ Only Kong LoadBalancer (172.18.255.190) is internet-facing

Layer 2 — Transport (mTLS)
  └─ PeerAuthentication STRICT mesh-wide
  └─ All pod-to-pod traffic is encrypted + mutually authenticated
  └─ Plain HTTP between services is rejected

Layer 3 — Identity (SPIFFE)
  └─ AuthorizationPolicy deny-all in every namespace
  └─ Only named SPIFFE principals are whitelisted per port
  └─ IngressGateway → Services (by service-account identity)
  └─ Service → Service (by service-account identity)

Layer 4 — Authentication (JWT)
  └─ RequestAuthentication validates JWT signature, issuer, expiry
  └─ Invalid token → 401 (Istio rejects immediately)
  └─ No token → DENY policy fires → 403

Layer 5 — Authorization (RBAC)
  └─ DENY wrong-namespace tokens before ALLOW can match
  └─ ALLOW only if groups=senior-group OR correct namespace role
  └─ senior-group → all namespaces
  └─ junior-group → own namespace only
```

---

## 10. Files Reference

| File | Purpose |
|------|---------|
| `security/peer-authentication.yaml` | Mesh-wide mTLS STRICT |
| `security/authz-retail-banking-ingress.yaml` | Deny-all + allow Kong/healthcheck for retail-banking-ingress |
| `security/authz-payments-ingress.yaml` | Deny-all + allow Kong/healthcheck for payments-ingress |
| `security/authz-grc-ingress.yaml` | Deny-all + allow Kong/healthcheck for grc-ingress |
| `security/authz-retail-banking.yaml` | Deny-all + SPIFFE ALLOW for retail-banking-team services |
| `security/authz-payments.yaml` | Deny-all + SPIFFE ALLOW for payments-team services |
| `security/authz-grc.yaml` | Deny-all + SPIFFE ALLOW for grc-team services |
| `keycloak/02-request-authentication.yaml` | JWT validation rules (issuer, JWKS URI) |
| `keycloak/03-authz-policy-jwt.yaml` | JWT group/role DENY + ALLOW policies |
| `minimal-profile.yaml` | IstioOperator — ClusterIP service type for all IngressGateways |

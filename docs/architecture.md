# Kong Distributed API Gateway Architecture

This document explains the project visually with Mermaid diagrams. GitHub renders these diagrams automatically in Markdown.

## 1. High-Level Architecture

```mermaid
flowchart LR
    user[Client / Browser]
    r53[Route 53<br/>mini-apps.click]

    subgraph eks[Amazon EKS Cluster]
        subgraph rbkic[Namespace: retail-banking-kic]
            rbgw[Gateway<br/>retail-banking-kong-api-gateway]
            rbproxy[Service<br/>retail-banking-kic-gateway-proxy]
        end

        subgraph paykic[Namespace: payments-kic]
            paygw[Gateway<br/>payments-kong-api-gateway]
            payproxy[Service<br/>payments-kic-gateway-proxy]
        end

        subgraph grckic[Namespace: grc-kic]
            grcgw[Gateway<br/>grc-kong-api-gateway]
            grcproxy[Service<br/>grc-kic-gateway-proxy]
        end

        subgraph rbapp[Namespace: retail-banking]
            rbroute[HTTPRoute<br/>customer-profile-httproute]
            cpsvc[customer-profile-svc]
            acctsvc[account-svc]
            stmtsvc[statement-svc]
        end

        subgraph payapp[Namespace: payments]
            payroute[HTTPRoute<br/>transfer-httproute]
            transfersvc[transfer-svc]
            pgsvc[payment-gateway-svc]
            fxsvc[fx-svc]
        end

        subgraph grcapp[Namespace: grc]
            grcroute[HTTPRoute<br/>fraud-httproute]
            fraudsvc[fraud-svc]
            auditsvc[audit-svc]
            sanctionsvc[sanction-svc]
        end
    end

    user --> r53
    r53 -->|retail-banking.mini-apps.click| rbproxy
    r53 -->|payments.mini-apps.click| payproxy
    r53 -->|grc.mini-apps.click| grcproxy

    rbproxy --> rbgw --> rbroute --> cpsvc --> acctsvc --> stmtsvc
    payproxy --> paygw --> payroute --> transfersvc --> pgsvc --> fxsvc
    grcproxy --> grcgw --> grcroute --> fraudsvc --> auditsvc --> sanctionsvc
```

## 2. Direct Domain Gateway Flow

This is the active public access pattern for the three `mini-apps.click` records.

```mermaid
sequenceDiagram
    participant Client
    participant DNS as Route 53
    participant Kong as Domain Kong Gateway
    participant Route as Domain HTTPRoute
    participant Entry as Entry Service
    participant Downstream as Downstream Services

    Client->>DNS: Resolve retail-banking.mini-apps.click
    DNS-->>Client: Kong LoadBalancer address
    Client->>Kong: HTTP or HTTPS request with Host header
    Kong->>Route: Match hostname and path /
    Route->>Entry: Forward to backendRef service
    Entry->>Downstream: Call domain service chain
    Downstream-->>Entry: Return downstream response
    Entry-->>Client: Return fake-service response
```

Domain mappings:

| Hostname | Kong Gateway | HTTPRoute | Backend chain |
| --- | --- | --- | --- |
| `retail-banking.mini-apps.click` | `retail-banking-kong-api-gateway` | `customer-profile-httproute` | `customer-profile-svc -> account-svc -> statement-svc` |
| `payments.mini-apps.click` | `payments-kong-api-gateway` | `transfer-httproute` | `transfer-svc -> payment-gateway-svc -> fx-svc` |
| `grc.mini-apps.click` | `grc-kong-api-gateway` | `fraud-httproute` | `fraud-svc -> audit-svc -> sanction-svc` |

## 3. Optional Centralized Global Gateway Flow

The global gateway tier can sit in front of the domain gateways and route by path prefix.

```mermaid
flowchart LR
    client[Client]

    subgraph global[Global Gateway Tier]
        gclass[GatewayClass<br/>global-kong-gatewayclass]
        ggw[Gateway<br/>global-kong-api-gateway]
        groute[HTTPRoute<br/>global-httproute]
    end

    subgraph grants[Cross-Namespace Permission]
        rg1[ReferenceGrant<br/>retail-banking-kic]
        rg2[ReferenceGrant<br/>payments-kic]
        rg3[ReferenceGrant<br/>grc-kic]
    end

    subgraph domain[Domain Gateway Tier]
        rb[retail-banking-kic-gateway-proxy]
        pay[payments-kic-gateway-proxy]
        grc[grc-kic-gateway-proxy]
    end

    subgraph apps[Backend Domains]
        rba[Retail Banking Services]
        paya[Payments Services]
        grca[GRC Services]
    end

    client --> ggw
    gclass --> ggw
    ggw --> groute

    groute -->|/retail-banking| rb --> rba
    groute -->|/payments| pay --> paya
    groute -->|/grc| grc --> grca

    rg1 -. allows backendRef .-> rb
    rg2 -. allows backendRef .-> pay
    rg3 -. allows backendRef .-> grc
```

Important idea: `ReferenceGrant` is created in the target namespace. It allows an `HTTPRoute` from `global-api-gateway-ns` to reference Services in the downstream KIC namespaces.

## 4. Namespace and Ownership Model

```mermaid
flowchart TB
    subgraph controllers[Kong Controller / Gateway Namespaces]
        globalKic[global-kic]
        rbKic[retail-banking-kic]
        payKic[payments-kic]
        grcKic[grc-kic]
    end

    subgraph routes[Route and Application Namespaces]
        globalRoutes[global-api-gateway-ns]
        rbApp[retail-banking]
        payApp[payments]
        grcApp[grc]
    end

    globalKic --> globalRoutes
    rbKic --> rbApp
    payKic --> payApp
    grcKic --> grcApp
```

Each domain has its own controller name:

| Domain | Controller name |
| --- | --- |
| Retail Banking | `konghq.com/retail-banking-kong-gateway-controller` |
| Payments | `konghq.com/payments-kong-gateway-controller` |
| GRC | `konghq.com/grc-kong-gateway-controller` |
| Global | `konghq.com/global-kong-gateway-controller` |

## 5. HTTPS Automation Flow

```mermaid
flowchart LR
    tf[Terraform<br/>for_https/]
    le[Let's Encrypt<br/>ACME]
    r53[Route 53 DNS Validation]
    secret[Kubernetes TLS Secrets]
    gw[Gateway HTTPS Listeners<br/>port 443]
    client[Client]

    tf -->|request certs| le
    le -->|DNS challenge| r53
    r53 -->|validation OK| le
    le -->|certificate + private key| tf
    tf -->|create kubernetes.io/tls| secret
    tf -->|update Gateway listeners| gw
    client -->|HTTPS| gw
```

Terraform creates one TLS Secret per domain gateway namespace:

| Domain | Secret namespace | HTTPS hostname |
| --- | --- | --- |
| Retail Banking | `retail-banking-kic` | `https://retail-banking.mini-apps.click/` |
| Payments | `payments-kic` | `https://payments.mini-apps.click/` |
| GRC | `grc-kic` | `https://grc.mini-apps.click/` |

## 6. Deployment Order

```mermaid
flowchart TD
    a[Create or connect to EKS]
    b[Install Gateway API CRDs]
    c[Install Kong Helm releases]
    d[Apply GatewayClass resources]
    e[Apply Gateway resources]
    f[Deploy backend Services and Deployments]
    g[Apply HTTPRoutes]
    h[Create Route 53 alias records]
    i[Test HTTP]
    j[Optional: apply HTTPS Terraform]
    k[Test HTTPS]

    a --> b --> c --> d --> e --> f --> g --> h --> i --> j --> k
```

## 7. Troubleshooting Flow

```mermaid
flowchart TD
    start[Request fails]
    dns{Does DNS resolve?}
    kong{Does Kong respond?}
    route{HTTPRoute Accepted?}
    refs{ResolvedRefs True?}
    pods{Backend Pods Running?}
    ok[Traffic should work]

    start --> dns
    dns -->|No| fixdns[Check Route 53 alias and local resolver]
    dns -->|Yes| kong
    kong -->|No| fixlb[Check Kong LoadBalancer Service]
    kong -->|Yes| route
    route -->|No| fixroute[Check Gateway allowedRoutes and hostnames]
    route -->|Yes| refs
    refs -->|No| fixrefs[Check Service names, ports, and ReferenceGrant]
    refs -->|Yes| pods
    pods -->|No| fixpods[Check Deployments, selectors, and logs]
    pods -->|Yes| ok
```

Useful commands:

```bash
kubectl get gateway -A
kubectl get httproute -A
kubectl get referencegrant -A
kubectl get svc -A | grep gateway-proxy
kubectl get pods,svc -n retail-banking
kubectl get pods,svc -n payments
kubectl get pods,svc -n grc
```

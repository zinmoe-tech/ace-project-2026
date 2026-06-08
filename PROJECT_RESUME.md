Project: ACE - Global API Gateway with Domain-specific Gateways

Summary
-------
This repository demonstrates a pattern for exposing multiple domain-specific API Gateways behind a single global gateway. The global gateway (Kong) accepts external traffic and routes to downstream domain gateways (also Kong) using HTTPRoute and ExternalName/Service backends. Istio is used within clusters to provide mTLS between components, and examples include Retail Banking, Payments, and GRC domains with sample services and Kong plugins.

Key Components
--------------
- global-kic: Namespace containing the global Kong Ingress Controller and gateway resources.
- retail-banking-kic, payments-kic, grc-kic: Namespaces for downstream domain Kong API Gateway components.
- retail-banking-team, payments-team, grc-team: Application namespaces containing service workloads for each domain.
- Gateway API resources: `HTTPRoute` (e.g., `2-global-httproute.yaml`) used by the global gateway to route by path prefix and rewrite host/path for downstream gateways.
- Kong plugin manifests: Example plugins for Payments (rate-limiting, key-auth) located under `apps/payments/`.
- Istio manifests: `istio/` folder contains permissive/strict mTLS configs and DestinationRules for mutual TLS.

Architecture (path-based routing)
---------------------------------
Client -> mybank.mini-apps.click (global Kong) -> HTTPRoute path /retail-banking -> Service: retail-banking-kic-gateway-proxy (ExternalName/Service) -> downstream Kong gateway -> downstream HTTPRoute -> application service

Deployment notes
----------------
Follow `SETUP.md` in `Kong Global Gateway With ExternalName/` to deploy in this order:
1. Create global and domain namespaces.
2. Deploy global Kong and domain Kong (KIC) Gateways.
3. Deploy application services for Retail Banking, Payments, and GRC.
4. Apply HTTPRoute manifests (`2-global-httproute.yaml`) and domain HTTPRoutes.
5. Apply Kong plugin manifests before Routes that reference them (Payments).
6. Configure Istio mTLS in PERMISSIVE mode, verify sidecar injection, then switch to STRICT.
7. Configure DNS: `mybank.mini-apps.click -> global Kong Gateway load balancer` (CNAME pointing to ELB DNS name).

How HTTPRoute works in this repo
--------------------------------
The single `global-httproute` routes requests by path prefixes:
- /retail-banking -> backend service `retail-banking-kic-gateway-proxy` and rewrites Host to `retail-banking.mini-apps.click` and strips prefix `/retail-banking`.
- /payments -> backend service `payments-kic-gateway-proxy`, rewrites Host to `payments.mini-apps.click`.
- /grc -> backend service `grc-kic-gateway-proxy`, rewrites Host to `grc.mini-apps.click`.

DNS record guidance
-------------------
- For public HTTPS access to `https://mybank.mini-apps.click/retail-banking` create a CNAME record named `mybank` that points to the external load balancer DNS name of the global Kong Gateway (e.g., `abc123.elb.amazonaws.com`).
- Do NOT include scheme (`http://`/`https://`) in the DNS value. Use a CNAME for ALB/ELB DNS names. If your provider supports alias/A records (Route 53 alias), you may use an alias A record pointing to the ELB.

Verification and troubleshooting
-------------------------------
- Confirm global gateway service external address:
  kubectl get svc -n global-kic
- Verify HTTPRoute and Gateway:
  kubectl get httproute -n global-api-gateway-ns
  kubectl get gateway -n global-kic
- Verify downstream services exist:
  kubectl get svc -n retail-banking-kic
- If you get "no Route matched with those values" from Kong (example response in your message), check:
  - The Host header being sent by the client: the global `HTTPRoute` expects `Host: mybank.mini-apps.click` (path-based routing + hostname in HTTPRoute).
  - The global Kong proxy reached the HTTPRoute (check Gateway/HTTPRoute status and events).
  - The backend Service names are correct and DNS resolves to the downstream gateway.
  - For HTTPS: ensure TLS certs are installed on the global gateway or use a TLS listener and valid cert.

Quick curl examples
-------------------
- HTTP test (once DNS points to global gateway ELB):
  curl -i http://mybank.mini-apps.click/retail-banking

- HTTPS test (if TLS configured on global Kong and cert valid):
  curl -ik https://mybank.mini-apps.click/retail-banking

- Payments route with API key header:
  curl -i http://mybank.mini-apps.click/payments -H "apikey: payments-demo-key"

Maintainers & next steps
------------------------
- Owners: see repo `README.md` and `SETUP.md` for contact and operational notes.
- Next improvements: automation (helm/terraform) for deploying Kong and Istio, central logging/monitoring, shared rate-limiting across Kong pods (redis-backed), add e2e tests for route rewrite behavior.

Contact
-------
For follow-up, provide the cluster `kubectl` context and I can help verify live resources and suggest precise fixes.
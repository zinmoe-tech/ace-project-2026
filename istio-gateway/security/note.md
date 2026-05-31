1. All application pods run as privileged: true
Every business service (account, payments, fraud, etc.) has full root access to the host node. If any pod is compromised, the attacker owns the node.


retail-banking-team   account-svc          → privileged: true  ❌
retail-banking-team   customer-profile-svc → privileged: true  ❌
retail-banking-team   statement-svc        → privileged: true  ❌
payments-team         transfer-svc         → privileged: true  ❌
payments-team         payment-gateway-svc  → privileged: true  ❌
payments-team         fx-svc               → privileged: true  ❌
grc-team              fraud-svc            → privileged: true  ❌
grc-team              audit-svc            → privileged: true  ❌
grc-team              sanction-svc         → privileged: true  ❌
2. No mTLS between services
PeerAuthentication → none. All service-to-service traffic is plain HTTP inside the cluster — anyone on the cluster network can intercept it.

3. No AuthorizationPolicies
Any service can call any other service freely. account-svc could directly call fraud-svc or payment-gateway-svc with no restriction.

4. No NetworkPolicies
No network-level isolation. Any pod in any namespace can reach any other pod directly.

5. HTTP only — no TLS on ingress
All traffic through Kong and Istio gateways is plain HTTP. No HTTPS configured anywhere.

🟡 Medium Issues
6. No sidecar injection on namespaces
istio-injection=enabled is missing on retail-banking-team, payments-team, grc-team. Without sidecars, mTLS can't be enforced even if you add PeerAuthentication.

7. No namespace isolation labels
No pod-security.kubernetes.io/enforce labels on business namespaces (unlike metallb-system which has them).

Summary Table
Security Control	Status
mTLS (PeerAuthentication)	❌ None
Service AuthorizationPolicy	❌ None
NetworkPolicy	❌ None
Pod privilege (non-root)	❌ All privileged
TLS on ingress (HTTPS)	❌ HTTP only
Sidecar injection	❌ Not enabled
Namespace pod security	❌ Not enforced
Where would you like to start fixing? I'd recommend this order:

Remove privileged: true from pods (most critical)
Enable sidecar injection + enforce mTLS
Add AuthorizationPolicies
Add NetworkPolicies
Enable HTTPS on gateways
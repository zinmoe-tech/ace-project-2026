# Issue Summary: Kong Global Gateway Upstream TLS Error

Date: 2026-05-05

## Symptom

Calling the global Kong load balancer with the expected host header failed:

```bash
curl -H "Host: mybank.mini-apps.click" \
  http://a7da198036c7449b0a06e4908fd90432-1924724727.ap-southeast-1.elb.amazonaws.com/payments
```

The response was `503 Service Unavailable`:

```text
upstream connect error or disconnect/reset before headers. retried and the latest reset reason: remote connection failure, transport failure reason: TLS_error:|268435703:SSL routines:OPENSSL_internal:WRONG_VERSION_NUMBER:TLS_error_end
```

The same failure happened for all global routes:

- `/payments`
- `/retail-banking`
- `/grc`

## Impact

The global gateway was reachable, but it could not proxy traffic to any internal domain Kong gateway. End users calling `mybank.mini-apps.click` received `503` responses for all domain paths.

## Root Cause

The domain Kong gateway pods had this Istio annotation:

```text
traffic.sidecar.istio.io/includeInboundPorts: ""
```

That prevented Istio from capturing inbound traffic to Kong's proxy ports. The caller sidecar attempted Istio mTLS, but the receiving Kong container got TLS traffic directly on its plaintext HTTP listener, causing the `WRONG_VERSION_NUMBER` TLS error.

The affected domain KIC gateway proxy ports were:

- `8000` for HTTP
- `8443` for HTTPS

## Fix Applied

Updated the domain Kong gateway Deployments and Helm releases so Istio captures inbound Kong proxy traffic:

```text
traffic.sidecar.istio.io/includeInboundPorts: "8000,8443"
```

The fix was applied to:

- `retail-banking-kic-gateway`
- `payments-kic-gateway`
- `grc-kic-gateway`

The setup documentation was also updated so future Helm installs include:

```bash
--set-string gateway.podAnnotations."traffic\.sidecar\.istio\.io/includeInboundPorts"="8000\,8443"
```

## Verification

After the rollout completed, all global routes returned `200 OK`:

```bash
curl -i -H "Host: mybank.mini-apps.click" http://a7da198036c7449b0a06e4908fd90432-1924724727.ap-southeast-1.elb.amazonaws.com/payments
curl -i -H "Host: mybank.mini-apps.click" http://a7da198036c7449b0a06e4908fd90432-1924724727.ap-southeast-1.elb.amazonaws.com/retail-banking
curl -i -H "Host: mybank.mini-apps.click" http://a7da198036c7449b0a06e4908fd90432-1924724727.ap-southeast-1.elb.amazonaws.com/grc
```

The payments Kong gateway pod was also confirmed to have the corrected annotation:

```text
payments-kic-gateway-75794856db-2t696  8000,8443
```

## Prevention

Keep the inbound Istio capture annotation in the Helm install and upgrade commands for internal domain Kong gateways. If the annotation is missing or empty, global-to-domain gateway traffic can fail with the same upstream TLS error.

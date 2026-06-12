# SIMPLE TLS Mode — Proof of Concept

Terminating TLS at the global Istio gateway using **SIMPLE** mode
(one-way TLS: the server presents a certificate, the client is **not** asked
for one — exactly how a normal `https://` website works).

## What "TLS termination" means here

The encrypted tunnel **ends at the gateway**. The gateway decrypts the request,
reads the HTTP path (`/grc/audits`), and routes it onward. To do that it needs:

- a **certificate** (`finance.crt`) — the gateway's public ID card, shown to the client
- a **private key** (`finance.key`) — the secret that decrypts; only the gateway holds it

We self-sign these (fine for a test). In production a real CA (e.g. Let's Encrypt)
signs the certificate instead.

```text
client --HTTPS(encrypted)--> [ global-istio-gateway ]  <-- TLS terminates HERE
                                     | decrypts, reads /grc/audits
                                     v
                             team gateway -> fraud-svc -> audit-svc -> sanction-svc
```

## Prerequisites

- Global gateway is up and reachable on its LoadBalancer IP (`172.19.255.200`).
- Plain HTTP on `:80` already works (see the curl test in `README.md`).

---

## Step 1 — Create the certificate + key

Generates `finance.crt` (ID card) and `finance.key` (secret key).

```bash
openssl req -x509 -newkey rsa:2048 -nodes -days 365 \
  -keyout finance.key -out finance.crt \
  -subj "/CN=finance.hellocloud.io/O=HelloCloudBank" \
  -addext "subjectAltName=DNS:finance.hellocloud.io"
```

| flag | meaning |
|------|---------|
| `req -x509` | make a self-signed certificate |
| `-newkey rsa:2048` | also generate a fresh 2048-bit key |
| `-nodes` | no password on the key (gateway must read it automatically) |
| `-days 365` | valid for one year |
| `-subj ".../CN=finance.hellocloud.io"` | name on the ID card = the hostname |
| `-addext "subjectAltName=DNS:..."` | **required** — TLS clients verify the SAN, not the CN |

Verify:
```bash
ls -l finance.crt finance.key
```

---

## Step 2 — Load the cert+key as a Kubernetes Secret

Istio's gateway reads its certificate from a **Secret**, not from loose files.
The Secret MUST live in the gateway pod's namespace (`global-istio-ingress`),
and its name MUST match `credentialName: finance-tls` in the Gateway.

```bash
kubectl -n global-istio-ingress create secret tls finance-tls \
  --cert=finance.crt --key=finance.key
```

Verify (type should be `kubernetes.io/tls`):
```bash
kubectl -n global-istio-ingress get secret finance-tls
```

---

## Step 3 — Turn on the HTTPS listener

`01-global-gateway.yaml` already has the `:443` server block (mode `SIMPLE`,
`credentialName: finance-tls`). Apply it:

```bash
kubectl apply -k k8s-idp/global-istio-gw
```

The relevant block:
```yaml
- port:
    number: 443
    name: https
    protocol: HTTPS
  hosts:
  - finance.hellocloud.io
  tls:
    mode: SIMPLE
    credentialName: finance-tls
```

---

## Step 4 — Prove TLS termination

`finance.hellocloud.io` isn't real DNS, so `--resolve` maps it to the gateway IP.

**4a) Quick check** (`-k` ignores the self-signed warning):
```bash
curl -vk --resolve finance.hellocloud.io:443:172.19.255.200 \
  https://finance.hellocloud.io/grc/audits
```

**4b) The real proof** (`--cacert` trusts our cert; no `-k`):
```bash
curl -v --cacert finance.crt --resolve finance.hellocloud.io:443:172.19.255.200 \
  https://finance.hellocloud.io/grc/audits
```

### What proves it worked

| Line in `curl -v` | Meaning |
|-------------------|---------|
| `SSL connection using TLSv1.3 ...` | traffic is encrypted |
| `subject: CN=finance.hellocloud.io` | gateway presented our cert |
| `SSL certificate verify ok` (in 4b) | **TLS terminated at the gateway with our cert** |
| `HTTP/2 200` + `fraud-svc` JSON | after decrypting, it still routed `/grc/audits` |

### Inspect the served certificate (optional)
```bash
openssl s_client -connect 172.19.255.200:443 -servername finance.hellocloud.io </dev/null 2>/dev/null \
  | openssl x509 -noout -subject -issuer -dates -ext subjectAltName
```

---

## Notes

- HTTP `:80` is intentionally still enabled alongside `:443` for comparison.
  For production, enable the `httpsRedirect` block in `01-global-gateway.yaml`
  so `:80` 301-redirects to `:443`.
- The `finance-tls` Secret holds a private key — it is created manually and is
  **not** committed to Git (keep it out of the kustomize bundle).
- Next mode to test: **MUTUAL** — same as SIMPLE but the gateway also *requires*
  and validates a client certificate during the handshake.

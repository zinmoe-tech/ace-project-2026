# Session 11 — Issues, Causes, and Solutions

This file is intentionally written as a troubleshooting study log.

## Issue 1 — `vault: command not found`

### Symptom

```text
vault: command not found
```

### Cause

Vault CLI was not installed on that host.

### Lesson

The Vault server can be remote, but the machine where you type `vault ...` still needs the Vault CLI.

---

## Issue 2 — Vault CLI tries `127.0.0.1:8200`

### Symptom

```text
WARNING! VAULT_ADDR and -address unset.
Defaulting to https://127.0.0.1:8200
```

then:

```text
connect: connection refused
```

### Cause

`VAULT_ADDR` was not configured.

### Fix

```bash
export VAULT_ADDR="https://vault-cluster-private-vault-7f4a955b.ae025b2d.z1.hashicorp.cloud:8200"
export VAULT_NAMESPACE="admin"
```

### Lesson

CLI configuration is independent from the fact that HCP Vault exists remotely.

---

## Issue 3 — `nslookup` returns NXDOMAIN

### Wrong command

```bash
nslookup https://vault-hostname:8200
```

### Cause

DNS resolves hostnames, not full URLs.

### Fix

```bash
nslookup vault-hostname
```

---

## Issue 4 — Interactive SSH fails after authentication

### Symptom

```text
PTY allocation request failed on channel 0
```

### Cause

The Vault-issued SSH certificate did not permit PTY allocation.

### Fix

Add to the role:

```json
{
  "allowed_extensions": "permit-pty",
  "default_extensions": {
    "permit-pty": ""
  }
}
```

### Lesson

Successful authentication does not automatically grant every SSH certificate extension.

---

## Issue 5 — `systemctl reload sshd` fails

### Symptom

```text
Unit sshd.service not found
```

### Cause

On this Ubuntu target the service is named:

```text
ssh.service
```

### Fix

```bash
sudo systemctl reload ssh
```

---

## Issue 6 — `journalctl | jq` fails

### Symptom

```text
jq: parse error: Invalid numeric literal
```

### Cause

Default journal output adds non-JSON prefixes.

### Fix

```bash
sudo journalctl \
  -u boundary-worker.service \
  -o cat \
  --no-pager \
| jq .
```

---

## Issue 7 — No worker entries in selected time window

### Symptom

```text
-- No entries --
```

### Cause

The selected time did not match the worker's journal timestamps/timezone.

### Fix

Widen the range and confirm whether displayed timestamps are UTC or local time.

Example:

```bash
sudo journalctl -u boundary-worker.service \
  --since "2026-09-01 17:25:30" \
  --until "2026-09-01 17:27:20" \
  --no-pager \
  -o cat | jq
```

### Lesson

Always normalize correlation timestamps to UTC.

---

## Issue 8 — Could not find Boundary logs in Datadog

### Initial assumption

Search for:

```text
source:boundary
```

### Actual observation

Boundary HCP audit streaming appeared under:

```text
source:hcp
```

with Boundary-identifying attributes such as:

```text
hcp_product = boundary
resource.type = hashicorp.boundary.cluster
stream.topic = hashicorp.boundary.cluster.audit
```

### Lesson

Do not guess Datadog tags. Open a known event first and inspect its actual fields.

---

## Issue 9 — Vault signing-path text search returned nothing

### Problem

Searching plain text:

```text
boundary-ssh/sign/boundary-client
```

did not initially find the expected event.

### Better method

Start with:

```text
source:vault
```

Open a Vault event and inspect structured fields.

The audit record later showed:

```text
http.url_details.path = boundary-ssh/sign/boundary-client
request.path = boundary-ssh/sign/boundary-client
request.request_uri = /v1/boundary-ssh/sign/boundary-client
```

### Lesson

Structured-log field searches are more reliable than assuming raw message text.

---

## Issue 10 — Expected worker log to show full Vault request

### Observation

Worker showed:

```text
COMMAND_VAULT_PROXY_POST
```

but not the complete HTTP request body.

### Explanation

Worker system events and Vault audit events serve different purposes.

Use:

```text
Worker logs -> prove Boundary worker action/proxy behavior
Vault audit -> prove exact Vault API operation
Target sshd -> prove certificate authentication
```

Do not try to make one log source prove the entire chain.

---

## Issue 11 — Manual certificate does not match Boundary certificate

### Cause

They are different signing events.

Manual:

```text
our /tmp/poc-key.pub -> Vault -> manual cert
```

Boundary:

```text
Boundary ephemeral public key -> Vault -> Boundary cert
```

### Lesson

Different:

```text
fingerprint
serial
key ID
certificate
```

is expected.

---

## Issue 12 — Vault audit feature availability

The original cluster tier did not provide the audit capabilities needed for this exercise. The lab was later run on a production/Standard tier where audit streaming was available.

### Lesson

Check HCP tier capabilities before designing an audit/monitoring POC.

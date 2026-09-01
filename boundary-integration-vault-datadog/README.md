# HCP Boundary + HCP Vault SSH — Beginner Study Notes

These notes split the lab into small study sessions instead of one large procedure.

## Recommended study order

1. [Session 01 — Understand the Architecture](01-architecture-and-concepts.md)
2. [Session 02 — Network and Prerequisites](02-network-and-prerequisites.md)
3. [Session 03 — Build the Vault SSH CA](03-vault-ssh-ca.md)
4. [Session 04 — Manual Vault-Signed SSH](04-manual-vault-ssh.md)
5. [Session 05 — Prepare Vault for Boundary](05-vault-policy-and-boundary-token.md)
6. [Session 06 — Configure Boundary Automatic SSH](06-boundary-auto-ssh.md)
7. [Session 07 — Understand the Automatic Credential Flow](07-auto-ssh-flow-explained.md)
8. [Session 08 — Configure and Read Worker/Target Logs](08-worker-and-target-logs.md)
9. [Session 09 — Stream HCP Audit Logs to Datadog](09-datadog-audit-streaming.md)
10. [Session 10 — Correlate One SSH Session End-to-End](10-end-to-end-correlation.md)
11. [Session 11 — Issues, Causes, and Solutions](11-issues-and-solutions.md)
12. [Session 12 — Security Lessons and Cleanup](12-security-and-cleanup.md)

## What this lab proves

```text
User
  |
  v
HCP Boundary
  |
  v
Boundary Egress Worker (10.1.10.4)
  | \
  |  \-- asks Vault to sign an ephemeral SSH public key
  |        |
  |        v
  |     HCP Vault SSH CA
  |        |
  |        \-- returns short-lived SSH certificate
  |
  v
Target VM (10.1.20.4:22)
  |
  \-- trusts the Vault CA and accepts the certificate
```

The important learning point is that **Vault is the SSH Certificate Authority** and **Boundary automates obtaining and injecting the short-lived credential**. The target does not need the user's permanent public key in `authorized_keys`.

# Session 12 — Security Lessons and Cleanup

## Goal

Understand what should remain after the lab and what must never be published.

## Short-lived credentials

The role uses:

```text
TTL = 10 minutes
```

This reduces the useful lifetime of a stolen SSH certificate.

## No static target user key distribution

The target trusts:

```text
Vault CA public key
```

rather than requiring a permanent public key from every user.

## Least privilege

Boundary's Vault token uses:

```text
boundary-controller
boundary-ssh-policy
```

The SSH policy is restricted to:

```text
boundary-ssh/sign/boundary-client
```

## Secrets that must NOT go to GitHub

Never commit:

```text
Vault tokens
Vault token accessors
Datadog API keys
Boundary auth tokens
SSH private keys
.env files containing secrets
```

Suggested `.gitignore`:

```gitignore
*.key
*.pem
*.token
*.secret
.env
.env.*
poc-key
poc-key.pub
poc-key-cert.pub
vault-sign-response.json
```

## If a token was pasted or exposed

Revoke/rotate it.

Do not rely on deleting it from a README after it has already been committed.

## Remove manual test keys

```bash
rm -f \
  /tmp/poc-key \
  /tmp/poc-key.pub \
  /tmp/poc-key-cert.pub \
  /tmp/vault-sign-response.json
```

## Main security model to remember

```text
Identity/authorization
        Boundary
           |
           v
Dynamic credential
          Vault
           |
           v
Private network access
     Boundary Worker
           |
           v
Local cryptographic verification
       Target SSHD
```

Each component has one clear responsibility.

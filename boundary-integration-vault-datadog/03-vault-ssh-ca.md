# Session 03 — Build the Vault SSH Certificate Authority

## Goal

Turn Vault into an SSH CA that can issue short-lived user certificates.

## Step 1 — Enable SSH secrets engine

```bash
vault secrets enable -path=boundary-ssh ssh
```

### Why?

A Vault secrets engine provides a specific type of secret operation.

The SSH engine can sign SSH public keys.

`boundary-ssh` is our chosen mount name, so paths begin with:

```text
boundary-ssh/
```

## Step 2 — Generate the SSH CA

```bash
vault write boundary-ssh/config/ca generate_signing_key=true
```

### Why?

A CA has:

```text
CA private key -> remains protected by Vault
CA public key  -> copied to SSH targets
```

Vault uses the private CA key to sign certificates. The target only needs the public CA key.

Read it:

```bash
vault read -field=public_key boundary-ssh/config/ca
```

Fingerprint it:

```bash
vault read -field=public_key boundary-ssh/config/ca | ssh-keygen -lf -
```

## Step 3 — Create the signing role

```bash
vault write boundary-ssh/roles/boundary-client - <<'EOF'
{
  "key_type": "ca",
  "allow_user_certificates": true,
  "allowed_users": "azureuser",
  "default_user": "azureuser",
  "ttl": "10m",
  "max_ttl": "10m",
  "allowed_extensions": "permit-pty",
  "default_extensions": {
    "permit-pty": ""
  }
}
EOF
```

## Why create a role?

The **CA** answers:

> Who signs the certificate?

The **role** answers:

> What kind of certificate is Vault allowed to issue?

Our role limits issuance to:

```text
SSH user certificate
user/principal = azureuser
TTL            = 10 minutes
PTY            = permitted
```

Without the role, Vault would not know the certificate rules Boundary should use.

## Why `permit-pty`?

We initially authenticated successfully but received:

```text
PTY allocation request failed on channel 0
```

Authentication and interactive-terminal permission are separate.

Adding:

```json
"default_extensions": {
  "permit-pty": ""
}
```

allows the signed certificate to request an interactive terminal.

## Verify

```bash
vault read boundary-ssh/roles/boundary-client
```

## Study checkpoint

Remember:

```text
SSH engine = capability
CA         = signer
Role       = certificate rules
```

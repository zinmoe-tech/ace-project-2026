# Session 05 — Vault Policies and the Boundary Token

## Goal

Allow Boundary to use Vault without giving Boundary unrestricted Vault access.

## Why do we need policies?

Vault follows least privilege.

A token should not automatically be able to:

```text
read every secret
change Vault configuration
create arbitrary credentials
```

A policy explicitly defines what the token may do.

## Policy 1 — Boundary token lifecycle

```bash
vault policy write boundary-controller - <<'EOF'
path "auth/token/lookup-self" {
  capabilities = ["read"]
}

path "auth/token/renew-self" {
  capabilities = ["update"]
}

path "auth/token/revoke-self" {
  capabilities = ["update"]
}

path "sys/leases/renew" {
  capabilities = ["update"]
}

path "sys/leases/revoke" {
  capabilities = ["update"]
}

path "sys/capabilities-self" {
  capabilities = ["update"]
}
EOF
```

### Why?

Boundary needs lifecycle/capability operations for the Vault credential store token.

This policy does **not** grant SSH signing by itself.

## Policy 2 — SSH signing permission

```bash
vault policy write boundary-ssh-policy - <<'EOF'
path "boundary-ssh/sign/boundary-client" {
  capabilities = ["create", "update"]
}
EOF
```

### Why?

This is the important least-privilege permission:

```text
Boundary may sign using:
boundary-ssh/sign/boundary-client
```

It does not grant arbitrary access to all Vault paths.

## Create Boundary's Vault token

```bash
vault token create \
  -no-default-policy=true \
  -policy="boundary-controller" \
  -policy="boundary-ssh-policy" \
  -orphan=true \
  -period=24h \
  -renewable=true
```

## Why these options?

### `-no-default-policy=true`

Avoid unnecessary permissions from the default policy.

### `-orphan=true`

The token is not tied to a normal parent-token revocation chain.

### `-period=24h`

This is a periodic service token. It can continue to live while an authorized client such as Boundary renews it.

### `-renewable=true`

Boundary can renew the token instead of requiring a manually replaced token every day.

## Verify capability

```bash
VAULT_TOKEN="$TEST_VAULT_TOKEN" \
vault token capabilities boundary-ssh/sign/boundary-client
```

Expected:

```text
create, update
```

## Security rule

Never put the real token in:

```text
README
Git
screenshots
tickets
chat transcripts intended for publication
```

If a token is exposed, revoke/rotate it.

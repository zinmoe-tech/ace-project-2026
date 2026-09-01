# Session 04 — Manual Vault-Signed SSH

## Goal

Prove Vault certificate signing and target CA trust **before** adding Boundary automation.

This is an important troubleshooting technique: test one layer at a time.

## Step 1 — Configure target to trust Vault CA

On the target VM, create:

```text
/etc/ssh/trusted-user-ca-keys.pem
```

Put the output of this command into it:

```bash
vault read -field=public_key boundary-ssh/config/ca
```

Configure SSHD:

```bash
sudo tee /etc/ssh/sshd_config.d/99-boundary-ca.conf > /dev/null <<'EOF'
TrustedUserCAKeys /etc/ssh/trusted-user-ca-keys.pem
EOF
```

Validate and reload:

```bash
sudo sshd -t
sudo systemctl reload ssh
sudo sshd -T | grep trustedusercakeys
```

Expected:

```text
trustedusercakeys /etc/ssh/trusted-user-ca-keys.pem
```

## Step 2 — Compare CA fingerprints

On the Vault-connected admin/bastion host:

```bash
vault read -field=public_key boundary-ssh/config/ca | ssh-keygen -lf -
```

On the target:

```bash
sudo ssh-keygen -lf /etc/ssh/trusted-user-ca-keys.pem
```

They must match.

### Why?

This proves:

```text
Vault signs with CA private key
           +
Target trusts matching CA public key
```

## Step 3 — Generate temporary SSH key

```bash
rm -f /tmp/poc-key /tmp/poc-key.pub /tmp/poc-key-cert.pub

ssh-keygen \
  -t ed25519 \
  -f /tmp/poc-key \
  -N "" \
  -C "boundary-poc"
```

Files:

```text
/tmp/poc-key       private key
/tmp/poc-key.pub   public key
```

## Step 4 — Ask Vault to sign the public key

```bash
vault write -format=json \
  boundary-ssh/sign/boundary-client \
  public_key=@/tmp/poc-key.pub \
  valid_principals="azureuser" \
  > /tmp/vault-sign-response.json
```

### What is happening?

```text
Public key
    |
    v
POST/UPDATE boundary-ssh/sign/boundary-client
    |
    v
Vault SSH role validates request
    |
    v
Vault CA signs public key
    |
    v
SSH certificate
```

The private key is **not sent to Vault**.

## Step 5 — Extract and inspect certificate

```bash
jq -r '.data.signed_key' \
  /tmp/vault-sign-response.json \
  > /tmp/poc-key-cert.pub
```

```bash
ssh-keygen -Lf /tmp/poc-key-cert.pub
```

Check:

```text
Type
Key ID
Serial
Valid period
Principals
Extensions
```

## Step 6 — Connect manually

```bash
ssh \
  -i /tmp/poc-key \
  -o CertificateFile=/tmp/poc-key-cert.pub \
  azureuser@10.1.20.4
```

If this succeeds, we have proven:

```text
Vault SSH CA       OK
Vault role         OK
Certificate        OK
Target CA trust    OK
SSH user           OK
Network to target  OK
```

Boundary is not involved yet.

## Important

This manual certificate will NOT match the later Boundary certificate.

Boundary generates another ephemeral credential for its own session.

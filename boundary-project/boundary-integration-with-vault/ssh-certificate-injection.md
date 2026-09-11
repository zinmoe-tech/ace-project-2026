# Boundary + Vault SSH certificate injection

Use Vault to issue short-lived SSH certificates for Boundary sessions instead
of storing `key/linux_key` in Boundary.

For the full picture, see
[Boundary with HCP Vault overall diagram](overall-architecture-diagram.md).

## Current state

The Azure project currently injects one static SSH private key:

- `boundary_credentials.tf` creates `boundary_credential_store_static.linux_targets`
- `boundary_credential_ssh_private_key.linux_target_key` reads `key/linux_key`
- all four `boundary_target` resources use that credential ID in
  `injected_application_credential_source_ids`

Keep the Azure `admin_ssh_key` only as a bootstrap or break-glass key. For
Boundary access, move to Vault SSH certificates.

## Target design

1. Vault owns an SSH CA.
2. Every target VM trusts the Vault SSH CA public key.
3. Boundary has a Vault credential store.
4. Boundary has a Vault SSH certificate credential library.
5. Each SSH target injects the credential library, not the static private key.

Boundary can use either Vault endpoint:

- `ssh-client-signer/sign/boundary-client`: Boundary generates the private key
  and Vault signs it.
- `ssh-client-signer/issue/boundary-client`: Vault generates and signs the
  keypair.

Use `sign` unless you specifically want Vault to generate the keypair.

## 0. Prerequisite: connect Azure to Vault

Before configuring Vault SSH certificates, make sure the Boundary worker or
controller in Azure can reach Vault on TCP `8200`.

Use the separate beginner guide first:

- [Azure to Vault network connectivity](azure-vault-network-connectivity.md)

## 1. Configure Vault

Run this as a Vault admin. Do not commit the token or CA private key.

Run the Vault commands from any terminal that has the Vault CLI installed and
can reach your Vault server. If you are not sure the CLI is installed, check:

```bash
vault version
```

Before running the commands, know these Vault CLI basics:

- `VAULT_ADDR` tells the `vault` CLI which Vault server to talk to.
- `vault login` authenticates your terminal session to Vault.
- `vault secrets enable` turns on a Vault secrets engine at a path.
- `vault write` creates or updates Vault configuration.
- `vault read` reads Vault configuration or generated values.
- `-field=public_key` prints only one field from the Vault response.

Replace `<vault-address>` with your Vault URL. Example:
`https://vault.example.com` or `http://127.0.0.1:8200`.

### 1.1 Point the CLI at Vault

```bash
export VAULT_ADDR="https://<vault-address>"
```

Check that the CLI can reach Vault:

```bash
vault status
```

### 1.2 Log in to Vault

```bash
vault login
```

Vault will ask for a token. Paste an admin/root token, then press Enter.

### 1.3 Enable the SSH secrets engine

This creates a new Vault path called `ssh-client-signer`. Boundary will later
ask this path for SSH certificates.

```bash
vault secrets enable -path=ssh-client-signer ssh
```

If you see an error like `path is already in use`, it probably means this step
was already done. You can continue.

### 1.4 Create the Vault SSH CA

This makes Vault generate and store the SSH CA private key internally. The
private key stays inside Vault.

```bash
vault write ssh-client-signer/config/ca generate_signing_key=true
```

### 1.5 Create the Boundary SSH role

This role controls what kind of SSH certificate Boundary is allowed to request.
Here it can request certificates for the Linux user `azureuser`, valid for 1
hour by default and up to 8 hours maximum.

```bash
vault write ssh-client-signer/roles/boundary-client \
  key_type=ca \
  allow_user_certificates=true \
  allowed_users="azureuser" \
  default_user="azureuser" \
  ttl="1h" \
  max_ttl="8h" \
  allowed_extensions="permit-pty" \
  default_extensions='{"permit-pty":""}'
```

What the important fields mean:

- `allowed_users="azureuser"`: Vault will only issue certificates for this SSH
  username.
- `default_user="azureuser"`: if no username is supplied, use `azureuser`.
- `ttl="1h"`: certificates expire after 1 hour by default.
- `max_ttl="8h"`: even if requested, certificates cannot last longer than 8
  hours.
- `permit-pty`: allows an interactive SSH shell.

### 1.6 Save the Vault SSH CA public key

Target VMs need this public key so they can trust certificates signed by Vault.

```bash
vault read -field=public_key ssh-client-signer/config/ca > trusted-user-ca-keys.pem
```

Confirm the file was created:

```bash
cat trusted-user-ca-keys.pem
```

The output should start with something like `ssh-rsa`, `ecdsa-sha2-nistp256`,
or another SSH public key type.

### 1.7 Create a Vault policy for Boundary

Boundary should not use your admin token. It needs a limited Vault token that
can only ask Vault to sign SSH certificates.

Create a file named `boundary-ssh-certs.hcl`:

```bash
tee boundary-ssh-certs.hcl >/dev/null <<'EOF'
path "ssh-client-signer/sign/boundary-client" {
  capabilities = ["create", "update"]
}
EOF
```

Load that policy into Vault:

```bash
vault policy write boundary-ssh-certs boundary-ssh-certs.hcl
```

Create a token for Boundary from that policy:

```bash
vault token create -policy=boundary-ssh-certs -period=24h
```

Copy the `token` value from the output. That is the value you will later use as
`TF_VAR_boundary_vault_token`.

Use a periodic/renewable token in production and rotate it normally. For a lab,
the command above is enough to test the integration.

## 2. Make target VMs trust the Vault CA

On each linux target, install the CA public key and enable OpenSSH certificate
auth:

```bash
sudo install -o root -g root -m 0644 trusted-user-ca-keys.pem /etc/ssh/trusted-user-ca-keys.pem
echo 'TrustedUserCAKeys /etc/ssh/trusted-user-ca-keys.pem' | sudo tee /etc/ssh/sshd_config.d/10-vault-ssh-ca.conf
sudo sshd -t
sudo systemctl reload ssh
```

For Terraform automation, add cloud-init/custom data to the
`azurerm_linux_virtual_machine` target resources so every new target gets this
file and sshd config at boot.

## 3. Replace Boundary static key resources

In the Azure Terraform directory, replace the static credential resources in
`boundary_credentials.tf` with a Vault credential store and SSH certificate
library:

```hcl
variable "vault_addr" {
  type = string
}

variable "boundary_vault_token" {
  type      = string
  sensitive = true
}

resource "boundary_credential_store_vault" "linux_targets" {
  name        = "linux-targets-vault-cred-store"
  description = "Vault SSH certificate store for linux target VMs"
  address     = var.vault_addr
  token       = var.boundary_vault_token
  scope_id    = var.boundary_project_scope_id
}

resource "boundary_credential_library_vault_ssh_certificate" "linux_target_cert" {
  name                = "linux-target-ssh-cert"
  description         = "Short-lived SSH certificates for azureuser"
  credential_store_id = boundary_credential_store_vault.linux_targets.id
  path                = "ssh-client-signer/sign/boundary-client"
  username            = "azureuser"
  key_type            = "ecdsa"
  key_bits            = 521
  ttl                 = "1h"

  extensions = {
    permit-pty = ""
  }
}
```

Pass secrets only through the environment:

```bash
export TF_VAR_vault_addr="https://<vault-address>"
export TF_VAR_boundary_vault_token="<vault-token-for-boundary>"
```

## 4. Point targets at the Vault credential library

Change each target from:

```hcl
injected_application_credential_source_ids = [
  boundary_credential_ssh_private_key.linux_target_key.id,
]
```

to:

```hcl
injected_application_credential_source_ids = [
  boundary_credential_library_vault_ssh_certificate.linux_target_cert.id,
]
```

Files to update:

- `boundary_linux_target_static_registration.tf`
- `boundary_linux_target_dynamic_registration.tf`

## 5. Apply and test

```bash
terraform fmt
terraform plan
terraform apply
```

Then connect with Boundary:

```bash
boundary targets list -scope-id <project-id>
boundary connect ssh -target-id <target-id>
```

If the session starts but SSH auth fails, check these first:

- target has `/etc/ssh/trusted-user-ca-keys.pem`
- target sshd config includes `TrustedUserCAKeys`
- Vault role allows `azureuser`
- credential library TTL is not shorter than the target session length
- target uses `type = "ssh"`, not `type = "tcp"`

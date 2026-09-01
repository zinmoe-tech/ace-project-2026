# Session 06 — Configure Boundary Automatic SSH

## Goal

Replace the manual `vault write` + `ssh` process with Boundary credential injection.

## Step 1 — Vault Credential Store

In Boundary project:

```text
integration-vault-project
```

Create:

```text
Name:      vault-ssh-credential-store
Type:      Vault
Namespace: admin
Address:   https://vault-cluster-private-vault-7f4a955b.ae025b2d.z1.hashicorp.cloud:8200
```

Use the Vault token created in Session 05.

Worker filter used in the lab:

```text
"vault" in "/tags/method"
```

## Why create a credential store?

The credential store tells Boundary:

> This is the Vault instance that Boundary may contact to obtain dynamic credentials.

It contains the integration information, not the target-specific SSH signing rule.

## Step 2 — SSH Certificate Credential Library

Create:

```text
Name: vault-ssh-credential-library
Type: SSH Certificates
Vault path: boundary-ssh/sign/boundary-client
Username: azureuser
```

## Why create a credential library?

The store answers:

> Which Vault?

The library answers:

> Which credential should Boundary request from that Vault?

In our case:

```text
Vault store
   |
   +-- credential library
          |
          +-- boundary-ssh/sign/boundary-client
          +-- SSH certificate
          +-- azureuser
```

## Step 3 — Configure target

```text
Name: boundary-target-01
Type: SSH
Address: 10.1.20.4
Port: 22
```

Attach:

```text
vault-ssh-credential-library
```

under **Injected Application Credentials**.

## Why attach it to the target?

Boundary now knows:

```text
When someone connects to THIS target,
obtain THIS dynamic credential
from THIS Vault credential library.
```

## Result

The user starts a Boundary SSH session without manually running:

```bash
ssh-keygen
vault write ...
ssh -i ...
```

Boundary automates that process.

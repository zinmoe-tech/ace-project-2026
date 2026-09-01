# Session 01 — Architecture and Concepts

## Goal

Understand what Boundary, Vault, the worker, and the target each do before configuring anything.

## Components

### HCP Boundary

Boundary controls **who may connect to which target** and brokers the session.

Boundary is not the SSH Certificate Authority in this lab.

### HCP Vault

Vault is the **SSH Certificate Authority (CA)**.

Its job is:

1. receive an SSH public key,
2. verify the request is authorized,
3. sign that public key,
4. return a short-lived OpenSSH certificate.

### Boundary egress worker

The egress worker is close to the private target network.

In this lab:

```text
egress-worker-01
10.1.10.4
```

It participates in the Vault credential flow and establishes the SSH connection toward:

```text
boundary-target-01
10.1.20.4:22
```

### Target VM

The target runs OpenSSH.

Instead of trusting a permanent user key, SSHD trusts the **Vault CA public key**:

```text
TrustedUserCAKeys /etc/ssh/trusted-user-ca-keys.pem
```

## Why use an SSH CA?

Traditional SSH often looks like:

```text
User private key
      |
      v
Target authorized_keys
```

This creates long-lived credentials that must be distributed and removed.

Our design is:

```text
Ephemeral key
     |
     v
Vault signs it
     |
     v
Short-lived certificate
     |
     v
Target trusts Vault CA
```

The target only needs to trust the CA.

## Manual versus automatic test

### Manual

We create a key ourselves and call Vault:

```text
ssh-keygen
   -> vault write boundary-ssh/sign/boundary-client
   -> certificate
   -> ssh target
```

Purpose: prove Vault + target SSH CA trust works independently of Boundary.

### Automatic

Boundary generates/manages the ephemeral credential workflow:

```text
Boundary session
   -> worker/Vault signing operation
   -> temporary certificate
   -> SSH target
```

Purpose: prove users do not need to manually create or handle the SSH credential.

## Study checkpoint

You should be able to explain:

- Boundary = access/session broker.
- Vault = SSH CA.
- Worker = private-network execution/proxy point.
- Target = trusts Vault CA.
- SSH certificate != ordinary SSH public key.

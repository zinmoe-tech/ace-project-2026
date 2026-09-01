# Session 02 — Network and Prerequisites

## Goal

Confirm that networking works before troubleshooting Vault or Boundary configuration.

## Lab addresses

```text
Boundary egress worker: 10.1.10.4
Target VM:               10.1.20.4
Target SSH port:         22
Vault API port:          8200
Vault namespace:         admin
```

Vault private endpoint used in the lab:

```text
vault-cluster-private-vault-7f4a955b.ae025b2d.z1.hashicorp.cloud
```

## Important DNS lesson

This is wrong:

```bash
nslookup https://vault.example.com:8200
```

`nslookup` expects a hostname, not `https://` and not a port.

Correct form:

```bash
nslookup vault-cluster-private-vault-7f4a955b.ae025b2d.z1.hashicorp.cloud
```

## Configure Vault CLI

Run from the bastion/admin host that can reach Vault:

```bash
export VAULT_ADDR="https://vault-cluster-private-vault-7f4a955b.ae025b2d.z1.hashicorp.cloud:8200"
export VAULT_NAMESPACE="admin"
```

Then:

```bash
vault login
```

## Why these environment variables?

Without `VAULT_ADDR`, Vault CLI defaults to:

```text
https://127.0.0.1:8200
```

That caused this lab error:

```text
dial tcp 127.0.0.1:8200: connect: connection refused
```

`VAULT_NAMESPACE=admin` is required because HCP Vault Dedicated operations in this lab are performed in the `admin` namespace.

## Required connectivity

```text
Boundary Worker ---> Vault : TCP/8200
Boundary Worker ---> Target: TCP/22
```

The target itself does not require Internet access for this SSH authentication model.

## Study checkpoint

Do not troubleshoot policies until DNS, TCP reachability, `VAULT_ADDR`, and `VAULT_NAMESPACE` are correct.

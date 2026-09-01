# Session 09 — HCP Audit Logs to Datadog

## Goal

Centralize Boundary and Vault evidence in Datadog.

# Part A — HCP Vault Audit Logs

The lab was moved to a Vault tier that supports audit log streaming.

In HCP:

```text
Vault Dedicated
  -> vault-cluster
  -> Audit logs
  -> configure Datadog
```

Datadog site used:

```text
US1
```

Use a Datadog API key.

## Why Vault audit logs matter

Worker logs show:

```text
COMMAND_VAULT_PROXY_POST
```

Vault audit logs show the actual Vault operation, for example:

```text
operation: update
path: boundary-ssh/sign/boundary-client
request_uri: /v1/boundary-ssh/sign/boundary-client
remote_address: 10.1.10.4
mount_type: ssh
namespace: admin/
```

This is much stronger proof of the credential-signing operation.

Sensitive values such as the public key/principal may be HMAC-protected in Vault audit output. That is expected.

# Part B — HCP Boundary Audit Streaming

In HCP:

```text
Boundary cluster
  -> Audit log streaming
  -> Datadog
```

The lab reached:

```text
Status: Streaming
Provider: Datadog
Endpoint: https://http-intake.logs.datadoghq.com/api/v2/logs
```

## Datadog sources observed

Vault:

```text
source:vault
```

Boundary/HCP:

```text
source:hcp
```

Do not assume `source:boundary`.

The Boundary audit records were under the HCP source and contained fields identifying:

```text
resource.type = hashicorp.boundary.cluster
stream.topic = hashicorp.boundary.cluster.audit
hcp_product = boundary
```

## Beginner hunting method

Start broad.

Vault:

```text
source:vault
```

Boundary:

```text
source:hcp
```

Then open one record and inspect its real field names before building a narrow filter.

This avoids guessing Datadog attribute paths.

# 05 — BoundarySessionCounter

## Why we keep this Lambda

Datadog can control the ASG directly, but it does not natively know the number of active HCP Boundary sessions.

This Lambda creates that metric.

## Flow

```text
EventBridge every minute
        ↓
BoundarySessionCounter
        ↓
Vault AWS IAM login
        ↓
Read Boundary monitor credentials
        ↓
Boundary API
        ↓
Count active sessions
        ↓
Read Datadog API key from Vault
        ↓
Datadog Metrics API
```

## Environment variables

```text
VAULT_ADDR=<HCP_VAULT_PRIVATE_ENDPOINT>
VAULT_NAMESPACE=admin
VAULT_AWS_ROLE=boundary-session-monitor-lambda
BOUNDARY_ADDR=<HCP_BOUNDARY_ADDR>
BOUNDARY_AUTH_METHOD_ID=<BOUNDARY_PASSWORD_AUTH_METHOD_ID>
BOUNDARY_SCOPE_ID=global
DD_SITE=datadoghq.com
```

## Schedule

```text
rate(1 minute)
```

## Metric

```text
boundary.active_sessions
```

Type: `Gauge`

Resource/tag:

```text
service:hcp-boundary
```

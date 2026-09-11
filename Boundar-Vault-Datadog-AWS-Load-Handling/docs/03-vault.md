# 03 — HCP Vault

## Why Vault is used

Vault removes long-lived secrets from EC2 user data and Lambda environment variables.

```text
AWS IAM Role
   ↓
Vault AWS Auth Role
   ↓
Vault Policy
   ↓
Short-lived Vault token
```

## KV v2 paths

```text
boundary-registration/asg-worker
boundary-registration/session-monitor
boundary-registration/datadog-metrics
boundary-registration/worker-cleanup
```

## AWS Auth roles

### boundary-asg-worker
- Bound AWS IAM role: `BoundaryWorkerRole`
- Vault policy: `boundary-asg-worker`
- Purpose: ASG worker registration secret access

### boundary-session-monitor-lambda
- Bound AWS IAM role: `BoundarySessionMonitorLambdaRole`
- Vault policy: `boundary-session-monitor`
- Purpose: Boundary monitoring credentials + Datadog API key

### boundary-worker-cleanup
- Bound AWS IAM role: `BoundaryWorkerCleanup-role-ro7ij99a`
- Vault policy: `boundary-worker-cleanup`
- Purpose: cleanup Boundary credentials

## Boundary Vault credential-store token

Use a token that is:

```text
orphan = true
renewable = true
periodic = true
```

Attach:

```text
boundary-controller
boundary-ssh-policy
```

## SSH Secrets Engine

```bash
vault secrets enable -path=boundary-ssh ssh
```

```bash
vault write boundary-ssh/config/ca generate_signing_key=true
```

```bash
vault write boundary-ssh/roles/boundary-client   key_type=ca   allow_user_certificates=true   allowed_users="azureuser"   default_user="azureuser"   ttl="10m"   max_ttl="10m"   not_before_duration="30s"
```

Why: Boundary sessions get short-lived SSH certificates instead of reusable static credentials.

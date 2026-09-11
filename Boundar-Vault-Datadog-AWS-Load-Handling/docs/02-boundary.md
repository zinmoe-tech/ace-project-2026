# 02 — HCP Boundary

## Why this configuration is needed

Boundary must know which workers can proxy target traffic, which workers can reach Vault, which identities may read sessions, and which identity may delete stale workers.

## Permanent worker

Keep one self-managed worker outside the ASG.

Recommended tags:

```hcl
tags {
  type       = ["egress"]
  cloud      = ["aws"]
  target     = ["on-aws"]
  cred-store = ["vault"]
}
```

Why: ASG desired capacity can be `0` while baseline Boundary connectivity remains available.

## Temporary ASG worker naming

Use:

```text
aws-asg-<EC2_INSTANCE_ID>
```

Why: the cleanup Lambda receives the terminating EC2 instance ID and can calculate the exact Boundary worker name.

## Session-monitor RBAC

Grant:

```text
ids=*;type=session;actions=list,read
```

Why: `BoundarySessionCounter` only needs read-only session access.

## Cleanup RBAC

Grant:

```text
type=worker;actions=list
ids=*;type=worker;actions=read,delete
```

Why: `BoundaryWorkerCleanup` must locate and delete the matching ASG worker.

## Vault Credential Store

Use a Vault credential-store token with:

```text
boundary-controller
boundary-ssh-policy
```

Why:
- `boundary-controller` manages token/lease lifecycle.
- `boundary-ssh-policy` allows SSH certificate signing.

## SSH Credential Library

Vault path:

```text
boundary-ssh/sign/boundary-client
```

Username:

```text
azureuser
```

TTL:

```text
10m
```

Attach it to the SSH target as an Injected Application Credential.

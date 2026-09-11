# 08 — Automatic Worker Cleanup

## Why cleanup is required

EC2 termination does not automatically delete the corresponding HCP Boundary worker record.

## Flow

```text
ASG Desired 1 → 0
      ↓
EC2 Terminating:Wait
      ↓
Lifecycle Hook
      ↓
EventBridge
      ↓
BoundaryWorkerCleanup
      ↓
Vault AWS Auth
      ↓
Read cleanup Boundary credential
      ↓
Boundary login
      ↓
Delete aws-asg-<instance-id>
      ↓
CompleteLifecycleAction
      ↓
EC2 terminates
```

## Lifecycle Hook

```text
Name: boundary-worker-terminate-cleanup
Transition: EC2_INSTANCE_TERMINATING
Heartbeat: 120 seconds
Default: CONTINUE
```

## EventBridge Rule

Target:

```text
BoundaryWorkerCleanup
```
